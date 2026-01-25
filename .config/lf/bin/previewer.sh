#!/usr/bin/zsh

CACHEDIR="$XDG_CACHE_HOME/lf"
[[ ! -d "$CACHEDIR" ]] && mkdir -p "$CACHEDIR"

# General purpose preview script, mainly meant for lf
# Architecture:
#   - Tries to cache as much as possible
#   - Handle filetypes as generic categories with fallback
#   - Coherent display between filetypes

# given to us by lf
FILE=$1
W=$2
H=$3
X=$4
Y=$5
LINES="$H"
COLUMNS="$W"

IMAGE_SIZE="800x600"

# Helper Functions {{{
# $1: image to display (file)
# $2: height offset
function display_image {
    [[ "$TERM" != "xterm-kitty" ]]&&exit 1
    kitten icat --silent --stdin no --transfer-mode memory \
        --align "${3:-center}" --place "${W}x$((H - ${2:-0}))@${X}x$((Y + ${2:-0}))" \
        "$1" < /dev/null > /dev/tty
}

function info {
    print -P "%F{cyan}%B# ${1}\e[0m\n"
    ((H-=2))
    ((Y+=2))
}

function title {
    print -P "%F{cyan}%B# ${1}\e[0m"
    ((H--))
    ((Y++))
}

function error {
    print -P "\n%F{red}%B! ${1}%f%b\n$2"
    ((H-=2))
    ((Y+=2))
}

function hint {
    print -P "%F{12}%B! ${1}%f%b\n$2"
    ((H--))
    ((Y++))
}

function prop {
    if [[ -z "$2" || "$2" == [[:space:]] ]]; then
        return
    fi
    print -P "%F{blue}$1%F{8}: %F{${3:-green}}${2}\e[0m"
    ((H--))
    ((Y++))
}

function section {
    print -P "\n%F{${2:-green}}%B| $1\e[0m"
    ((H-=2))
    ((Y+=2))
}

# create a cache entry for a file
# takes mtime into account, so changes to a file will result in different cache entries
# $1: filepath
# $@:2: entries to create names for
# $out: reply
# $return: whether the files need to be initialized
function create_cache {
    local id="$(stat -c "%m.%i.%Y" -- "$1" | sed 's/\//@/g')"

    for ((i=2; i <= $#; i++)); do
        reply[$i-1]="$CACHEDIR/${id}${argv[$i]}"
    done
    [[ ! -f "${reply[1]}" ]]
}
# }}}


if ! [[ -e "$FILE" ]]; then
    exit 1
elif ! [[ -r "$FILE" ]]; then
    print -P "%F{red}%B! Permission Denied\e[0m"
    exit 1
fi

MIMETYPE="$(file --dereference --brief --mime-type -- "$FILE")"

# Video {{{
function preview_video {
    if create_cache "${1}" .png .desc; then
        {
            IFS=$'\t' read -r audio_format audio_bitrate video_format video_bitrate video_resolution video_framerate video_duration < <(mediainfo --output=JSON "$1" \
                | jq -r '([.media.track|.[]|select(."@type" == "Video")][0]) as $video
                    | ([.media.track|.[]|select(."@type" == "Audio")][0]) as $audio
                    | "\($audio.Format)\t\($audio.BitRate)\t\($video.Format)\t\($video.BitRate)\t\($video.Width)x\($video.Height)\t\($video.FrameRate // "variable ")\t\($video.Duration)"'
            )
            seconds="${video_duration%.*}"
            minutes=$[seconds / 60]
            hours=$[minutes / 60]
            minutes=$[minutes % 60]
            seconds=$[seconds % 60]
            audio_bitrate=$[audio_bitrate / 1000]
            video_bitrate=$[video_bitrate / 1000000]
            ((audio_bitrate == 0)) && audio_bitrate="unknown bitrate" || audio_bitrate="${audio_bitrate}kbps"
            ((video_bitrate == 0)) && video_bitrate="unknown bitrate" || video_bitrate="${video_bitrate}mbps"
            if [[ "$audio_format" == "null" ]]; then
                audio="none"
            else
                audio="$audio_format (${audio_bitrate})"
            fi
            print "$audio\t$video_format\t$video_bitrate\t$video_resolution\t$video_framerate\t$hours\t$minutes\t$seconds" \
                > "${reply[2]}"
        }&
        ffmpegthumbnailer -s 512 -m -i "$1" -o "${reply[1]}"&
        wait
    fi

    IFS=$'\t' read -r audio video_format video_bitrate video_resolution video_framerate hours minutes seconds < "${reply[2]}"
    info "$video_format Video"
    prop "Audio" "$audio" 12
    prop "Video" "$video_format ($video_bitrate)" yellow
    prop "Resolution" "$video_resolution" magenta
    prop "Framerate " "${video_framerate}fps" magenta
    prop "Runtime" "${hours}:${minutes}:${seconds}" magenta
    display_image "${reply[1]}" 1
}
# }}}

# Images {{{
function preview_image {
    if [[ "$2" == "image/svg+xml" ]]; then
        info "Scalable Vector Graphic"
        if create_cache "$1" .png; then
            magick -background none -size 400x400 "$1" "${reply[1]}"
        fi
    else
        if create_cache "${1}" .png .desc; then
            magick "$1" -resize "$IMAGE_SIZE" "${reply[1]}"&
            identify -format $'%m\t%wx%h\t%z\t%[EXIF:Make] %[EXIF:Model]\t%C\t%l' "$1" > "${reply[2]}"&
            wait
        fi
        IFS=$'\t' read -r format size colordepth taken_by compression label < "${reply[2]}"
        info "$format Image"
        prop "Resolution" "$size" magenta
        prop "Bits per Pixel" "$colordepth" magenta
        prop "Taken by" "$taken_by"
        prop "Label" "$label"
        prop "Compression" "$compression" yellow
    fi
    display_image "${reply[1]}" 1 left
}
# }}}

# Audio {{{
function preview_audio {
    if create_cache "${1}" .png .desc; then
        mediainfo --output=JSON "$1" | jq -r '.media.track as $tracks
            | $tracks[] | select(."@type" == "General") as $meta
            | $tracks[] | select(."@type" == "Audio") as $audio
            | [
                $meta.Title // " ",
                $meta.Album // " ",
                $meta.Performer // " ",
                $meta.Genre // " ",
                $meta.Format // " ",
                ($meta.Duration | tonumber | round | strftime("%H:%M:%S")),
                ($meta.OverallBitRate | tonumber / 1000),
                ($audio.SamplingRate | tonumber / 1000),
                "\($audio.Channels) (\($audio.ChannelLayout // "unknown layout"))"
            ] | join("\t") ' > "${reply[2]}" &
        ffmpegthumbnailer -s 512 -m -i "$1" -o "${reply[1]}"&
        wait
    fi
    IFS=$'\t' read -r title album artist genre format time bitrate samplingrate channels < "${reply[2]}"
    info "$format Audio"
    prop "Title" "$title"
    prop "Artist" "$artist"
    prop "Album" "$album" 13
    prop "Genres" "$genre" yellow
    prop "Bitrate" "${bitrate} kbps" 12
    prop "Samplerate" "${samplingrate} kHz" 12
    prop "Channels" "$channels" yellow
    prop "Runtime" "$time" magenta

    display_image "${reply[1]}" 1 left
}
# }}}

# Executables and object files {{{
function preview_elf {
    case "$2" in
        application/x-pie-executable|application/x-executable)
            name="Executable"
            ;;
        application/x-sharedlib)
            name="Library"
            ;;
    esac
    info "ELF $name"
    readelf -h "$1"| while IFS="$IFS:" read -r field value; do
        case $field in
            Class) prop "Ver " "$value" magenta;;
            OS/ABI) prop "Abi " "$value";;
            Machine) prop "Arch" "$value";;
            Type) prop "Type" "$value" yellow;;
        esac
    done
    local -a libs=($(objdump -p -- "$1"|grep NEEDED|while read -r _ lib; do print -- "$lib"; done))
    if [[ "$libs" == "" ]]; then
        print -P "\n%F{12}Fully statically linked%f"
    else
        print -P "\n%B%F{blue}Linked against:\e[0m\n${(j:\n:)libs[@]}"
    fi
}

function preview_object {
    info "Object File"
    local -a funcs undef vars globals
    while read -r symbol type _; do
        case $type in
            T) funcs+="$symbol";;
            U) undef+="$symbol";;
            D) vars+="$symbol";;
            B) globals+="$symbol";;
        esac
    done <<< "$(nm -g --format=posix "$1")"
    print -P -- "%F{12}Functions: $#funcs\e[0m\n${(j:, :)funcs}\n\n%F{green}Variables: $#vars\e[0m\n${(j:, :)vars}\n\n%F{yellow}Globals: $#globals\e[0m\n${(j:, :)globals}\n\n%F{red}Undefined: $#undef\e[0m\n${(j:, :)undef}" \\n| fmt -sw $((W-4))
}

# }}}

# Documents {{{
function preview_pdf {
    if create_cache "$1" .png; then
        pdftoppm -singlefile -f 1 -l 1 -png "$1" > "${reply[1]}"
    fi
    display_image "${reply[1]}"
}

function preview_office {
    if create_cache "$1" ".png"; then
        libreoffice --convert-to pdf "$1" --outdir "$CACHEDIR" >/dev/null 2>&1
        outfile="$CACHEDIR/${1:t}" 2>/dev/null
        outfile="${outfile%.*}.pdf" 2>/dev/null
        pdftoppm -singlefile -f  1 -l 1 -png "$outfile" > "${reply[1]}" 2>/dev/null
        rm "$outfile"
    fi
    display_image "${reply[1]}"
}

function preview_font {
    info "Font"
    local example_text="ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz
01234567890 $€£¥
() {} [] <> \\\|/ +-*= ¿?¡! .,:; &%#@^
The quick brown fox jumps over the lazy dog.
Zwölf Boxkämpfer jagen Viktor quer über den großen Sylter Deich."
    if create_cache "${1}" .png .desc; then
        magick -background transparent -fill '#eceff4' -font "$1" \
            -pointsize 24 label:"$example_text" \
            "${reply[1]}" &
        fc-scan \
            --format="%{fullname}\t%{family}\t%{postscriptname}\t%{style}" \
            -- "$1" > "${reply[2]}"&
        wait
    fi
    IFS=$'\t' read name family psname style < "${reply[2]}"

    prop "Name" "$name"
    prop "PSName" "$psname" 12
    prop "Family" "$family" 13
    prop "Style" "$style" yellow
    display_image "${reply[1]}" 1 left
}

function preview_xopp {
    if create_cache "${1}" .png .data; then
        xournalpp-thumbnailer "$1" "${reply[1]}" 2>&1 >/dev/null &
        gzip -d - < "$1" | xq -r '.xournal.page | length, .[0].background."@filename"' > "${reply[2]}"
        wait
    fi
    {
        read -r pagecount
        read -r pdf
    } < "${reply[2]}"

    info "Xournal++ File"
    prop "Pages" "$pagecount" magenta
    prop "PDF File" "$pdf"
    display_image "${reply[1]}" 1 left
}
# }}}

# Archives {{{

function bsdtar_list {
    info "$2"
    local lastwasdir=1
    local lastdir=""
    local i=2

    bsdtar -vtf "$1" | LC_ALL=C sort -k 9 | head -n $[H-4] | while read -r perms _ owner group size _ _ _ name && ((i++ < H)); do
        if [[ "$name" == "." || "$name" == "/" || "$name" == "//" ]]; then
            continue
        fi
        local ftype="${perms:0:1}"
        case "$ftype" in
            d)
                if ((lastwasdir)); then
                    print -P "%F{cyan}%B${name%*/}/\e[0m"
                else
                    print -P "\n%F{cyan}%B${name%*/}/\e[0m"
                fi
                lastwasdir=1
                lastdir="$name"
                ;;
            l)
                lastwasdir=0
                IFS=">" read -r name target <<< "$name"
                name="${name:t}"
                print -P "%F{blue}${name%* -}%F{white} ->%F{blue}${target}\e[0m"
                ;;
            -)
                if [[ "${name}" != "${name:h1}" && "${lastdir}" == "" ]]; then
                    print -P "%F{cyan}%B${name:h1}/\e[0m"
                    lastdir="${name:h1}/"
                fi
                lastwasdir=0
                name="${name:t}"
                print -P "$name"
                ;;
        esac
    done
}

function preview_rar {
    info "rar Archive"
    local lastwasdir=1
    # has shitty output, convert it smth nicer
    unrar-free --list "$1" | awk \
        '/^[-]+$/ { in_list = !in_list; next }
        in_list { if (NR%2==0) {line = $0 } else { print $0 "\t" line} }' \
    | LC_ALL=C sort | while read size date time bits file; do
            if [[ "${bits:1:1}" == "D" ]]; then
                if ((lastwasdir)); then
                    print -P "%F{cyan}%B$file/\e[0m"
                else
                    print -P "\n%F{cyan}%B$file/\e[0m"
                fi
                lastwasdir=1
            else
                lastwasdir=0
                print "${file:t}"
            fi
    done
}

function preview_sqlite {
    title "sqlite3 Database"

    local curtbl=""
    local count=0
    while IFS="|" read -r table column ctype && ((H > 1)); do
        if [[ "$table" == "*Error" ]]; then
            error "Could not access database:" "$column"
            break
        fi
        if [[ -z "$column" ]]; then
            continue
        fi
        if [[ "$curtbl" != "$table" ]]; then
            section "$table" 7
            curtbl="$table"
        fi
        type="${ctype:l}"
        case "$type" in
            bigint) color=13;;
            blob) color=yellow;;
            boolean) color=cyan;;
            date|timestamp) color=yellow;;
            double|float|real) color=12;;
            int|integer) color=magenta;;
            longvarchar) color=green;;
            text|varchar|varchar*) color=green;;
            variant) color=12;;
            "") color=8; type=null;;
            *) color="green";;
        esac
        prop "$column" "$type" "$color"
    done < <(sqlite3 "$1" 'SELECT m.name, p.name, p.type
    FROM sqlite_master m
    left outer join pragma_table_info((m.name)) p
        on m.name <> p.name
        order by m.name, p.name;' 2> >(while read -r err; do print "*Error|$err"; done) || return)
}
# }}}

# Generic {{{
function preview_binary {
    info "Binary"
    # HACK: the ultimate WTF, i hope xxd comes up with a way to change the colors some day
    # this (in order):
    # removes bold, changes white to gray
    # changes red to light blue, makes lines that just have '*' gray, and makes the addresses magenta in all other places
    if create_cache "$1" .dump; then
        xxd -a -R always  -c 12 -u "$1" | head -n 80 | sed -e 's/1;//g' -e 's/37m/90m/g' \
            -e 's/31m/94m/g' -e $'s/^*/\e[90m*/g' -e 's/^\(.*\):/\x1b[35m\1\x1b[90m:/g' \
            | tee "${reply[1]}"
    else
        head -n$[H-1] "${reply[1]}"
    fi
}

function preview_text {
    COLORTERM=truecolor bat -pf --wrap=character --terminal-width=$[W-4] -f -r1:$[H - 2] "$FILE"
}
# }}}

case "$MIMETYPE" in
    application/pdf)
        preview_pdf "$FILE" "$MIMETYPE";;
    *opendocument*|application/vnd.openxmlformats-officedocument.*)
        preview_office "$FILE" "$MIMETYPE" ;;
    font/sfnt|application/vnd.ms-opentype)
        preview_font "$FILE" "$MIMETYPE"
        ;;

    image/*) preview_image "$FILE" "$MIMETYPE";;
    audio/*) preview_audio "$FILE" "$MIMETYPE";;
    video/*) preview_video "$FILE" "$MIMETYPE";;

    application/x-pie-executable|application/x-executable|application/x-sharedlib)
        preview_elf "$FILE" "$MIMETYPE";;
    application/x-object)
        preview_object "$FILE" "$MIMETYPE";;

    *x-iso9660-image)
        bsdtar_list "$FILE" "ISO Disk Image"
        ;;
    application/x-archive|application/x-cpio|application/x-tar|application/x-bzip2|application/gzip|application/x-lzip|application/x-lzma|application/x-xz|application/x-7z-compressed|application/vnd.android.package-archive|application/vnd.debian.binary-package|application/java-archive|application/x-gtar|application/zip)
        if [[ "$FILE"  == *.xopp ]]; then
            preview_xopp "$FILE"
        else
            type="${MIMETYPE#application/}"
            bsdtar_list "$FILE" "${type#*x-} Archive"
        fi
        ;;
    application/vnd.rar)
        preview_rar "$FILE"
        ;;
    application/vnd.sqlite3)
        preview_sqlite "$FILE"
        ;;

    text/*|*/xml|application/javascript|application/pgp-signature|application/x-setupscript|application/x-wine-extension-ini|application/x-pem-file)
        preview_text "$FILE" "$MIMETYPE"
        ;;
    application/json)
        jq -C < "$FILE"
        ;;

    # essentially all special cases
    inode/x-empty|application/x-empty)
        print -P "%SEmpty\e[0m"
        ;;
    *octet-stream)
        preview_binary "$FILE" "$MIMETYPE"
        ;;
    *)
        hint "No Handler installed for ${MIMETYPE}"
        if [[ "$(file --mime-encoding -b -- "$FILE")" == "binary" ]]; then
            preview_binary "$FILE" "$MIMETYPE"
        else
            info "Text"
            preview_text "$FILE" "$MIMETYPE"
        fi
        ;;
esac
exit 1
