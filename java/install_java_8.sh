# Check java version
JAVA_VER=$(java -version 2>&1 | sed 's/java version "\(.*\)\.\(.*\)\..*"/\1\2/; 1q')

if [ "$JAVA_VER" -lt 18 ]
then
    # Download jdk 8
    echo "Downloading and installing jdk 8"
    wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8-b132/jdk-8-linux-x64.rpm"

    # Silent install
    sudo yum -y install jdk-8-linux-x64.rpm

    # Figure out how many versions of Java we currently have
    NR_OF_OPTIONS=$(echo 0 | alternatives --config java 2>/dev/null | grep 'There ' | awk '{print $3}' | tail -1)

    echo "Found $NR_OF_OPTIONS existing versions of java. Adding new version."

    # Make the new java version available via /etc/alternatives
    sudo alternatives --install /usr/bin/java java /usr/java/default/bin/java 1

    # Make java 8 the default
    echo $(($NR_OF_OPTIONS + 1)) | sudo alternatives --config java

    # Set some variables
    export JAVA_HOME=/usr/java/default/bin/java
    export JRE_HOME=/usr/java/default/jre
    export PATH=$PATH:/usr/java/default/bin
fi

# Check java version again
JAVA_VER=$(java -version 2>&1 | sed 's/java version "\(.*\)\.\(.*\)\..*"/\1\2/; 1q')

echo "Java version is $JAVA_VER!"
echo "JAVA_HOME: $JAVA_HOME"
echo "JRE_HOME: $JRE_HOME"
echo "PATH: $PATH"
