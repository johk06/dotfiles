#include <errno.h>
#include <fcntl.h>
#include <linux/videodev2.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/ucontext.h>
#include <time.h>
#include <unistd.h>
#define WIDTH 640
#define HEIGHT 480
#define EASING 2000

struct {
  double max;
  double min;
  long int devmax;
} Config = {.max = 1.0, .min = 0.05};

struct Buffer {
  void *data;
  size_t length;
};

static char buf[8192];

static int repeat_ioctl(int fd, int req, void *arg) {
  int ret;
  do {
    ret = ioctl(fd, req, arg);
  } while (ret == -1 && errno == EINTR);
  return ret;
}
struct Buffer buffers[2] = {};
int open_stream(const char *dev) {
  int fd = open(dev, O_RDWR | O_NONBLOCK);
  if (fd < 0) {
    fprintf(stderr, "Failed to open %s: %s", dev, strerror(errno));
    return fd;
  }

  struct v4l2_format fmt = {.type = V4L2_BUF_TYPE_VIDEO_CAPTURE,
                            .fmt.pix = {
                                .width = WIDTH,
                                .height = HEIGHT,
                                .field = V4L2_FIELD_ANY,
                                .pixelformat = V4L2_PIX_FMT_YUYV,
                            }};
  struct v4l2_requestbuffers req = {
      .count = 2,
      .type = V4L2_BUF_TYPE_VIDEO_CAPTURE,
      .memory = V4L2_MEMORY_MMAP,
  };
  enum v4l2_buf_type typ;
  if (repeat_ioctl(fd, VIDIOC_S_FMT, &fmt) == 0) {
  } else {
    fprintf(stderr, "Failed to configure webcam for YUYV\n");
    close(fd);
    return -1;
  }

  int bufreq = repeat_ioctl(fd, VIDIOC_REQBUFS, &req);
  if (bufreq == -1 || req.count != 2) {
    fprintf(stderr, "Failed to request webcam buffers\n");
    close(fd);
    return -1;
  }

  for (size_t i = 0; i < req.count; i++) {
    struct v4l2_buffer buf = {};
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index = i;

    if (repeat_ioctl(fd, VIDIOC_QUERYBUF, &buf) == -1) {
      perror("Querying buffer");
      close(fd);
      return -1;
    }

    buffers[i].length = buf.length;
    buffers[i].data = mmap(NULL, buf.length, PROT_READ | PROT_WRITE, MAP_SHARED,
                           fd, buf.m.offset);
    if (buffers[i].data == MAP_FAILED) {
      perror("mmap");
      close(fd);
      return -1;
    }
  }

  for (size_t i = 0; i < req.count; i++) {
    struct v4l2_buffer buf = {};
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index = i;

    if (repeat_ioctl(fd, VIDIOC_QBUF, &buf) == -1) {
      perror("Queue buffer");
      close(fd);
      return -1;
    }
  }

  enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  if (repeat_ioctl(fd, VIDIOC_STREAMON, &type) == -1) {
    perror("Start streaming");
    close(fd);
    return -1;
  }

  return fd;
}

double clamp(double v, double min, double max) {
  if (v >= max) {
    return max;
  } else if (v <= min) {
    return min;
  }
  return v;
}

double cubic_transfer(double v) {
  if (v < 0.5) {
    return 4.0 * v * v * v;
  } else {
    return 1.0 - pow(-2.0 * v + 2.0, 3.0) / 2.0;
  }
}
double get_avg_brightness(struct Buffer *buf) {
  unsigned char *pixels = buf->data;
  double total_y = 0;
  for (size_t i = 0; i < WIDTH * HEIGHT; i++) {
    total_y += pixels[i * 2];
  }

  double bright = total_y / (WIDTH * HEIGHT * 255);
  return cubic_transfer(bright);
}

void write_brightness(int ctrl, double val) {

  double effective = Config.devmax * clamp(val, Config.min, Config.max);
  int count = snprintf(buf, sizeof(buf), "%ld\n", (long int)effective);
  write(ctrl, buf, count);
}
void set_brightness(int ctrl, double old, double target) {
  double cur = old;
  if (cur < target) {
    while (fabs(cur - target) > 1e-6) {
      cur = fmin(cur + 0.01, target);
      write_brightness(ctrl, cur);
      usleep(EASING);
    }
  } else {
    while (fabs(cur - target) > 1e-6) {
      cur = fmax(cur - 0.01, target);
      write_brightness(ctrl, cur);
      usleep(EASING);
    }
  }
}

long int get_max_brightness(char *dev) {
  snprintf(buf, sizeof(buf), "%s/max_brightness", dev);
  FILE *f = fopen(buf, "r");
  if (!f) {
    return -1;
  }
  long int cal = 0;
  fscanf(f, "%li", &cal);
  fclose(f);
  return cal;
}

int main(int argc, char **argv) {
  const char *dev = "/dev/video0";
  int stream = open_stream(dev);
  if (stream < 0) {
    return 1;
  }
  char *backlight = argv[1];
  if (!backlight) {
    backlight = "/sys/class/backlight/amdgpu_bl1";
  }
  long int max_brightness = get_max_brightness(backlight);
  if (max_brightness < 0) {
    fprintf(stderr, "Failed to get maximum brightness on %s: %s\n", backlight,
            strerror(errno));
    return 1;
  }
  Config.devmax = max_brightness;

  snprintf(buf, sizeof(buf), "%s/brightness", backlight);
  int brightness_control = open(buf, O_WRONLY);

  double last_brightness = -1;
  while (1) {
    struct v4l2_buffer buf = {.type = V4L2_BUF_TYPE_VIDEO_CAPTURE,
                              .memory = V4L2_MEMORY_MMAP};

    if (repeat_ioctl(stream, VIDIOC_DQBUF, &buf) == -1) {
      if (errno == EAGAIN) {
        usleep(10000);
        continue;
      }
      perror("Dequeue Buffer");
      break;
    }

    double brightness = get_avg_brightness(&buffers[buf.index]);
    double delta = fabs(brightness - last_brightness);
    if (delta > 0.005) {
      set_brightness(brightness_control, last_brightness, brightness);
      printf("%f\n", brightness);
      last_brightness = brightness;
    }

    if (repeat_ioctl(stream, VIDIOC_QBUF, &buf) == -1) {
      perror("Enqueue Buffer");
      break;
    }
    usleep(500000);
  }
}
