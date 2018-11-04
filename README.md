# Reencode media to HVEC using ffmpeg

These scripts reencodes your media files into HVEC to save disk space.

## Installation

Tested on Ubuntu 18.04.

Setup NVIDIA SDK and compile ffmpeg:

    wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
    sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
    sudo dpkg -i cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
    sudo apt-get update
    sudo apt-get install cuda
    echo "export PATH=/usr/local/cuda-10.0/bin:~/bin:\$PATH" >> ~/.bashrc
    echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:~/ffmpeg_build/lib/"  >> ~/.bashrc
    source ~/.bashrc
    # Compile ffmpeg
    ./build_ffmpeg.sh

Reboot to load the nvidia driver.

Install dependencies:

    sudo apt-get install -y ruby ruby-dev libsqlite3-dev libmediainfo-dev
    sudo gem install bundler
    bundle
    bundle exec rake db:create

## Usage

Analyze a directory recursively and calculate the estimated conversion time and space savings:

    bundle exec ruby -Ilib reencode analyze /path/to/media

Test reencoding (the files are encoded into the current working directory):

    bundle exec ruby -Ilib reencode perform /path/to/media

Use hardware decoding (does not always work):

    bundle exec ruby -Ilib reencode perform --hardware-decode /path/to/media

Actually replace the source media file after successful reencode:

    bundle exec ruby -Ilib reencode perform --inplace /path/to/media

Allow to retry failed encoding during the next run:

    bundle exec ruby -Ilib reencode retry

Unlock all files in the database (only needed after hard crashes):

    bundle exec ruby -Ilib reencode unlock

