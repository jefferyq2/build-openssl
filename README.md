## OpenSSL Building ##

This project provides some prebuilt OpenSSL configuration scripts for easy building on various platforms.  It contains as a submodule, the [k9webprotection/openssl][openssl-release] git projects.

You can check this directory out in any location on your computer, but the default location that the `build.sh` script looks for is as a parent directory to where you check out the [k9webprotection/openssl][openssl-release] git project.  By default, this project contains submodules of the [k9webprotection/openssl][openssl-release] git project in the correct locations.

[openssl-release]: https://github.com/openssl/openssl

### Requirements ###

The following are supported to build the OpenSSL project:

To build on macOS:

 * macOS 10.12 (Sierra)
 
 * Xcode 8.3 (From Mac App Store)
     * Run Xcode and accept all first-run prompts

 * Build dependencies
     * Autoconf
     * Automake
     * Libtool

To build on Windows:

 * Windows 10
 
 * Visual Studio 2017 (or 2015)
     * Make sure and install `Programming Languages | Visual C++ | Common Tools for Visual C++ 2017` as well
     * If you have both 2017 and 2015 installed, you can select to build for 2015 by setting `SET MSVC_VERSION=14.0` (the default is to use 14.1) prior to running the `build.bat` file.

 * ActivePerl 5.24 (MUST be ActivePerl)

To build for Android:

 * macOS requirements above
 
 * Android NDK r15b
     * You must set the environment variable `ANDROID_NDK_HOME` to point to your NDK installation

     
##### Steps (Bootstrap script) #####

The `build.sh` script accepts a "bootstrap" argument which will install the dependencies for building from Homebrew.  It can be run multiple times safely.

    ./build.sh bootstrap


### Build Steps ###

If you installed `autoconf` from homebrew, it may conflict with the `autoconf213` package and not be linked. If this has happened, you will want to run `brew link --overwrite  autoconf`

You can build the libraries using the `build.sh` script:

    ./build.sh [/path/to/openssl-dist] <plat.arch|plat|'bootstrap'|'clean'>

Run `./build.sh` itself to see details on its options.

You can modify the execution of the scripts by setting various environment variables.  See the script sources for lists of these variables.
