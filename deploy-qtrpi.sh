#!/bin/bash

source ${0%/*}/utils/common.sh
OUTPUT_DIR=$ROOT/raspi/qt5pi

check_env_vars

cd_root

function usage() {
    cat <<EOF
Usage: $0 [options]

-h| --help                      Display help text.
-p| --prepare-rpi               Prepare the Raspberry Pi device by:
                                - Installing package dependencies for Qt
                                - Add /usr/local/qt5pi/lib to the ldd list of directories
                                - Fix libEGL and libGLESv2 links
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    KEY="$1"
    case $KEY in
        -h|--help)
            DISPLAY_HELP=true
        ;;
        -p|--prepare-rpi)
            PREPARE_RPI=true
        ;;

        *)
        ;;
    esac
    shift
done

if [[ $DISPLAY_HELP ]]; then
    usage
    exit 0
fi

if [[ $PREPARE_RPI ]]; then
    TARGET_USER=$(echo $TARGET_HOST | cut -d@ -f1)
    ssh $TARGET_HOST "sudo mkdir /usr/local/qt5pi ; sudo chown -R ${TARGET_USER}:users /usr/local/qt5pi"
    ssh $TARGET_HOST 'sudo apt-get install -y apt-transport-https'
    ssh $TARGET_HOST 'sudo apt-get install -y libts-0.0-0 libinput10 fontconfig mc'
    ssh $TARGET_HOST "sudo sh -c 'echo /usr/local/qt5pi/lib > /etc/ld.so.conf.d/99-qt5pi.conf'"
    # TODO change /etc/gai.conf to force ipv4

ssh $TARGET_HOST 'sudo apt-get install -y libharfbuzz0b libpcre16-3 libdouble-conversion1 libxkbcommon0'
    # to fix which version of libEGL should be picked by Qt applications (/opt/vc rather than /usr/lib/....)
    # NOTE for debian stretch: see @link https://www.raspberrypi.org/blog/raspbian-stretch/#comment-1321445
    #          libharfbuzz0b  +
    #          libpcre16-3  +
    #          libdouble-conversion1 +
    #          libxkbcommon0 +
    ssh $TARGET_HOST "sudo sh -c 'rm /usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0 /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0'"
    ssh $TARGET_HOST "sudo sh -c 'ln -sf /opt/vc/lib/libbrcmEGL.so /usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0'"
    ssh $TARGET_HOST "sudo sh -c 'ln -sf /opt/vc/lib/libbrcmEGL.so /usr/lib/arm-linux-gnueabihf/libEGL.so.1'"
    ssh $TARGET_HOST "sudo sh -c 'ln -sf /opt/vc/lib/libbrcmEGL.so /usr/lib/arm-linux-gnueabihf/libEGL.so'"
    ssh $TARGET_HOST "sudo sh -c 'ln -sf /opt/vc/lib/libbrcmGLESv2.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0'"
    ssh $TARGET_HOST "sudo sh -c 'ln -sf /opt/vc/lib/libbrcmGLESv2.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2'"
    ssh $TARGET_HOST "sudo sh -c 'ln -sf /opt/vc/lib/libbrcmGLESv2.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so'"
fi

rsync -avz $OUTPUT_DIR $TARGET_HOST:/usr/local/
ssh $TARGET_HOST 'sudo ldconfig'

