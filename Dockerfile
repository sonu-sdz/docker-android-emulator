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

#==================
# Run appium server
#==================
ENTRYPOINT [ "sh", "-c", "appium" ]