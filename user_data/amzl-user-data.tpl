Content-Type: multipart/mixed; boundary="==BOUNDARY=="
MIME-Version: 1.0

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash -ex
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo 'installing additional software'
# installing in a loop to ensure the cli is intalled.
for i in {1..5}
do
  yum install -y aws-cli awslogs jq && break || sleep 60
done

echo 'setting info for ECS cluster configuration'
echo ECS_CLUSTER="${ecs_cluster_name}" >> /etc/ecs/ecs.config
echo ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"syslog\",\"awslogs\"] >> /etc/ecs/ecs.config

# Inject the CloudWatch Logs configuration file contents
cat > /etc/awslogs/awslogs.conf <<- EOF
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/ecs/ecs-agent.log]
file = /var/log/ecs/ecs-agent.log.*
log_group_name = ${ecs_log_group_name}
log_stream_name = {cluster}/{container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ


EOF

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
# Set the region to send CloudWatch Logs data to (the region where the container instance is located)
region=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
sed -i -e "s/region = us-east-1/region = $region/g" /etc/awslogs/awscli.conf

--==BOUNDARY==
Content-Type: text/upstart-job; charset="us-ascii"

#upstart-job
description "Configure and start CloudWatch Logs agent on Amazon ECS container instance"
author "Amazon Web Services"
start on started ecs

script
	exec 2>>/var/log/ecs/cloudwatch-logs-start.log
	set -x

	until curl -s http://localhost:51678/v1/metadata
	do
		sleep 1
	done

	# Grab the cluster and container instance ARN from instance metadata
	cluster=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .Cluster')
	container_instance_id=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .ContainerInstanceArn' | awk -F/ '{print $2}' )

	# Replace the cluster name and container instance ID placeholders with the actual values
	sed -i -e "s/{cluster}/$cluster/g" /etc/awslogs/awslogs.conf
	sed -i -e "s/{container_instance_id}/$container_instance_id/g" /etc/awslogs/awslogs.conf

	service awslogs start
	chkconfig awslogs on
end script
--==BOUNDARY==--
