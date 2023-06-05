# GEOS Installation on EMR

[GEOS](https://trac.osgeo.org/geos/) is a popular library for Geospatial analysis and is used by Python libraries like Shapely and GeoPandas for manipulating geographic data.

Let's see how to install another Python package, [Cartopy](https://scitools.org.uk/cartopy/docs/latest/index.html), for geospatial data processing.

## Bootstrap Action

Our bootstrap action needs to perform two main functions:

1. Install the GEOS library itself
2. Install our Python packages

Given that Cartopy requires GEOS 3.7.2 or greater, we unfortunately need to build it from source.

This also requires that we build proj from source as well as sqlite3 (instructions here: https://airflow.apache.org/docs/apache-airflow/stable/howto/set-up-database.html).

Once those are installed, we can `pip3 install cartopy` with a minor caveat that your sudo shell needs `/usr/local/bin` in its path because that's where the `geos-config` binary is.

## Running

Upload `install-geos.sh` from this repository to an S3 bucket and use `aws emr create-cluster`!

```bash
S3_BUCKET=dcortesi-demo-code-us-west-2
AWS_REGION=us-west-2

aws s3 cp geos/install-geos.sh s3://${S3_BUCKET}/code/bootstrap/geos/
aws emr create-cluster \
 --name "emr-cartopy" \
 --region ${AWS_REGION} \
 --bootstrap-actions Path="s3://${S3_BUCKET}/code/bootstrap/geos/install-geos.sh"  \
 --log-uri "s3n://${S3_BUCKET}/logs/emr/" \
 --release-label "emr-6.10.0" \
 --use-default-roles \
 --applications Name=Spark Name=Livy Name=JupyterEnterpriseGateway \
 --instance-fleets '[{"Name":"Primary","InstanceFleetType":"MASTER","TargetOnDemandCapacity":1,"TargetSpotCapacity":0,"InstanceTypeConfigs":[{"InstanceType":"c5a.2xlarge"},{"InstanceType":"m5a.2xlarge"},{"InstanceType":"r5a.2xlarge"}]},{"Name":"Core","InstanceFleetType":"CORE","TargetOnDemandCapacity":0,"TargetSpotCapacity":1,"InstanceTypeConfigs":[{"InstanceType":"c5a.2xlarge"},{"InstanceType":"m5a.2xlarge"},{"InstanceType":"r5a.2xlarge"}],"LaunchSpecifications":{"OnDemandSpecification":{"AllocationStrategy":"lowest-price"},"SpotSpecification":{"TimeoutDurationMinutes":10,"TimeoutAction":"SWITCH_TO_ON_DEMAND","AllocationStrategy":"capacity-optimized"}}}]' \
 --scale-down-behavior "TERMINATE_AT_TASK_COMPLETION" \
 --auto-termination-policy '{"IdleTimeout":14400}'
```

The cluster will take about 20 minutes to boot up due to needing to compile several projects from source.