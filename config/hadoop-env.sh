# ================================
# hadoop-env.sh
# ================================
# Environment variables for Hadoop runtime.

# Detect and export the OS type
export HADOOP_OS_TYPE=${HADOOP_OS_TYPE:-$(uname -s)}

# Set JAVA_HOME for Hadoop (specific to ARM64 in this case)
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64
