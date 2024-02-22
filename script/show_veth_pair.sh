function veth_interface_for_container() {
	local pid=$(docker inspect -f '{{.State.Pid}}' "$1")
	# Make the container's network namespace available to the ip-netns command:
	sudo ln -sf /proc/$pid/ns/net "/var/run/netns/$1"
	# Get the interface index of the container's eth0:
	local index=$(sudo ip netns exec "$1" ip link show eth0 | head -n1 | sed s/:.*//)
	# Increment the index to determine the veth index, which we assume is
	# always one greater than the container's index:
	let index=index+1
	# Write the name of the veth interface to stdout:
	ip link show | grep "^${index}:" | sed "s/${index}: \(.*\)@.*/\1/"
	# Clean up the netns symlink, since we don't need it anymore
	sudo rm -f "/var/run/netns/${1}"
}

docker ps -f name=docker-compose.* --format '{{.Names}}' | while read line; do echo "${line} $(veth_interface_for_container ${line})"; done
