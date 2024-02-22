#include <uapi/linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/udp.h>
#include <uapi/linux/ptrace.h>

#define IP_TCP 	6
#define ETH_HLEN 14
#define MSG_LEN 60

struct info {
  int src_addr;
  int dst_addr;
  __u64 span_id_1;
  __u64 span_id_2;
  char msg[MSG_LEN];
  __u64 timestamp;
};

BPF_HASH(metrics, struct info, u16);

static inline int swap_u16(__u16 in) {
  __u16 retval;
  char *conv16 = (char*) &in;
  char *ret16 = (char*) &retval;
  ret16[0]=conv16[1];   ret16[1]=conv16[0];
  return retval;
}

int store_metrics(struct __sk_buff *skb) {
	struct ethhdr eth;
	struct iphdr iph;
	struct tcphdr tcph;
	struct info key;
	memset(&key, 0, sizeof(key));
	__u16 *vp, value = 0;
	int ret;
	char msg[MSG_LEN];

	ret = bpf_skb_load_bytes(skb, 0, &eth, sizeof(eth));
	if (ret < 0)
		value = ret;

	ret = bpf_skb_load_bytes(skb, sizeof(eth), &iph, sizeof(iph));
	if (ret < 0)
		value = ret;

	if (iph.ihl < 6)
		goto DROP;

	ret = bpf_skb_load_bytes(skb, sizeof(eth) + iph.ihl * 4, &tcph, sizeof(tcph));
	if (ret < 0)
		value = ret;

	unsigned long p[7];
	int i = 0;
	__u32 payload_offset;
	payload_offset = ETH_HLEN + (iph.ihl * 4) + tcph.doff * 4;
	for (i = 0; i < 7; i++) {
		p[i] = load_byte(skb, payload_offset + i);
	}

	//find a match with an HTTP message
	//HTTP
	// if ((p[0] == 'H') && (p[1] == 'T') && (p[2] == 'T') && (p[3] == 'P')) {
	// 	goto KEEP;
	// }
	//GET
	if ((p[0] == 'G') && (p[1] == 'E') && (p[2] == 'T')) {
		goto KEEP;
	}
	//POST
	if ((p[0] == 'P') && (p[1] == 'O') && (p[2] == 'S') && (p[3] == 'T')) {
		goto KEEP;
	}
	//PUT
	if ((p[0] == 'P') && (p[1] == 'U') && (p[2] == 'T')) {
		goto KEEP;
	}
	//DELETE
	if ((p[0] == 'D') && (p[1] == 'E') && (p[2] == 'L') && (p[3] == 'E') && (p[4] == 'T') && (p[5] == 'E')) {
		goto KEEP;
	}
	//HEAD
	if ((p[0] == 'H') && (p[1] == 'E') && (p[2] == 'A') && (p[3] == 'D')) {
		goto KEEP;
	}

	//no HTTP match
	goto DROP;

	KEEP:
	ret = bpf_skb_load_bytes(skb, sizeof(eth) + sizeof(iph) + 2, &key.span_id_1, 8);
	if (ret < 0)
		value = ret;

	ret = bpf_skb_load_bytes(skb, sizeof(eth) + sizeof(iph) + 10, &key.span_id_2, 8);
	if (ret < 0)
		value = ret;

	ret = bpf_skb_load_bytes(skb, payload_offset, &key.msg, sizeof(key.msg));
	if (ret < 0)
		value = ret;
	
	key.dst_addr = iph.daddr;
	key.src_addr = iph.saddr;
	value = swap_u16(iph.tot_len);
	key.timestamp = bpf_ktime_get_ns();

	__u16* kptr = NULL;
    kptr = metrics.lookup(&key);
    if (kptr) {
        metrics.update(&key, &value);
    } else {
        metrics.insert(&key, &value);
    }

	return -1;

	DROP:
	return 0;
}
