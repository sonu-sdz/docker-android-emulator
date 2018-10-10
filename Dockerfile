FROM ubuntu:16.04

LABEL maintainer "Sonu Puthukudi <sonu.sdz@live.com>"

#=============
# Set WORKDIR
#=============
WORKDIR /root


#==================
# General Packages
#==================
RUN apt-get -qqy update && \
    apt-get upgrade -y && \
    apt-get -qqy --no-install-recommends install \
    openjdk-8-jdk \
    ca-certificates \
    zip \
    unzip \
    curl \
    wget \    
    && rm -rf /var/lib/apt/lists/*


#===============
# Set JAVA_HOME
#===============
ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/jre" \
    PATH=$PATH:$JAVA_HOME/bin


#=====================
# Install Android SDK
#=====================
ARG SDK_VERSION=sdk-tools-linux-4333796
ARG ANDROID_BUILD_TOOLS_VERSION=26.0.0
ARG ANDROID_PLATFORM_VERSION="android-25"

ENV SDK_VERSION=$SDK_VERSION \
    ANDROID_BUILD_TOOLS_VERSION=$ANDROID_BUILD_TOOLS_VERSION \
    ANDROID_HOME=/root

RUN wget -O tools.zip https://dl.google.com/android/repository/${SDK_VERSION}.zip && \
    unzip tools.zip && rm tools.zip && \
    chmod a+x -R $ANDROID_HOME && \
    chown -R root:root $ANDROID_HOME

ENV PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$JAVA_HOME/bin

RUN mkdir -p ~/.android && \
    touch ~/.android/repositories.cfg && \
    sdkmanager --update && \
    echo y | sdkmanager "platform-tools" && \
    echo y | sdkmanager "build-tools;$ANDROID_BUILD_TOOLS_VERSION" && \
    echo y | sdkmanager "platforms;$ANDROID_PLATFORM_VERSION"

ENV PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools


#===========================
# Install latest nodejs, npm
#===========================

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash
RUN apt-get install --yes nodejs 

#===============
# Install Appium
#===============
ARG APPIUM_VERSION=1.7.2
ENV APPIUM_VERSION=$APPIUM_VERSION
RUN npm install -g appium@${APPIUM_VERSION} --unsafe-perm=true --allow-root
RUN npm install -g appium-doctor

#===================
# Expose Appium port
#===================
EXPOSE 4723

#======================
# Scripts to run appium
#======================
COPY entry_point.sh \    
     /root/

RUN chmod +x /root/entry_point.sh

# ===============================================

ENV REFRESHED_APT_AT 2016-02-20

# Set locale to UTF-8 to fix the locale warnings
RUN localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 || :

# Set DEBIAN_FRONTEND to noninteractive, so dpkg will not wait for user inputs
ENV DEBIAN_FRONTEND noninteractive

# Installing the environment required: xserver, xdm, flux box, roc-filer and ssh
# and install some basic packages
# and clean up apt-get

RUN apt-get install -y lxde-core lxterminal xvfb x11vnc sudo && \
	apt-get install -y xterm && \
	apt-get clean

# Fix problems with Upstart and DBus inside a docker container.
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl

# Copy the files into the container
ADD . /x11-src
RUN chmod -R a=rX /x11-src

# Local user, may be overwritten by dependent build
ENV X11_USER xclient

# Resolution and color depth of simulated display
ENV RESOLUTION 1280x1024x16

VOLUME /home
EXPOSE 5900

# Start x11vnc
ENTRYPOINT ["/bin/bash", "/x11-src/startup.sh"]
CMD ["/usr/bin/lxterminal"]

#==================
# Run appium server
#==================
# ENTRYPOINT /root/entry_point.sh
