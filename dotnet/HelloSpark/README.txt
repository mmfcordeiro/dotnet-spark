User the commands below to build and run the example as outline at https://github.com/dotnet/spark/blob/master/docs/getting-started/ubuntu-instructions.md

dotnet build

cp people.json /dotnet/HelloSpark/bin/Debug/netcoreapp2.1
cd /dotnet/HelloSpark/bin/Debug/netcoreapp2.1

# Run locally
spark-submit --class org.apache.spark.deploy.dotnet.DotnetRunner --master local microsoft-spark-2.4.x-0.5.0.jar dotnet HelloSpark.dll

# To test out the example using the master and slave instances:
spark-submit --class org.apache.spark.deploy.dotnet.DotnetRunner --master spark://$HOSTNAME:$SPARK_MASTER_PORT microsoft-spark-2.4.x-0.5.0.jar dotnet HelloSpark.dll