#include <uapi/linux/bpf.h>
#include <linux/pkt_cls.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/udp.h>
#include <uapi/linux/string.h>

#define MSG_LEN 20
#define OPTION_TYPE 136
#define OPTION_LEN 18
#define TCP 6

static inline __u16 csum_fold_helper(__u32 csum) {
  if (csum >> 16) {
    __u16 hi, lo;
    hi = csum >> 16;
    lo = csum & 0xffff;
    csum = hi + lo;
  }
  return ~csum;
}

static inline int swap_u16(__u16 in) {
  __u16 retval;
  char *conv16 = (char*) &in;
  char *ret16 = (char*) &retval;
  ret16[0]=conv16[1];   ret16[1]=conv16[0];
  return retval;
}

static inline void ipv4_csum(void *data_start, int data_size,  __u32 *csum, __u32* id, __u16 oph) {
  int i;
  __u16 *hd = (__u16*) data_start;
  __u16 hi, lo;
  for (i=0;i<10;i++) {
    hi += hd[i] & 0xff;
    lo += hd[i] >> 8;
  }
  *csum = ((hi << 8) + lo);
  *csum += swap_u16(oph);
  for (i=0;i<4;i++) {
    *csum += swap_u16(id[i] >> 16);
    *csum += swap_u16(id[i] & 0xffff);
  }
  *csum = csum_fold_helper(*csum);
}

static inline void generate_id(__u32* id) {
  int i;
  __u32 gid;
  for (i = 0; i < 4; i ++) {
    gid = bpf_get_prandom_u32();
    id[i] = gid;
  }
}

int update_len(struct __sk_buff *skb) {
  struct ethhdr eth;
  struct iphdr iph;
  struct tcphdr tcph;
  int ret, value = 0;
  __u16 oph = (OPTION_LEN << 8) + OPTION_TYPE;
  __u32 id[4], cs = 0;
  
  ret = bpf_skb_load_bytes(skb, sizeof(eth), &iph, sizeof(iph));
  if(ret < 0)
    value = ret;

  ret = bpf_skb_load_bytes(skb, sizeof(eth) + sizeof(iph), &tcph, sizeof(tcph));
  if(ret < 0)
    value = ret;

  if(iph.protocol != TCP)
    return TC_ACT_OK;

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
	return TC_ACT_OK;

  KEEP:
  ret = bpf_skb_adjust_room(skb, MSG_LEN, BPF_ADJ_ROOM_NET, 0);
  if(ret < 0)
    value = ret;

  iph.ihl = 5 + (MSG_LEN / 4);
  iph.tot_len = swap_u16(swap_u16(iph.tot_len) + MSG_LEN);
  iph.check = 0;

  generate_id(id);
  ipv4_csum(&iph, sizeof(iph), &cs, id, oph);
  iph.check = swap_u16(cs);

  ret = bpf_skb_store_bytes(skb, sizeof(eth), &iph, sizeof(iph), BPF_F_RECOMPUTE_CSUM);
  if(ret < 0)
    value = ret;

  ret = bpf_skb_store_bytes(skb, sizeof(eth) + sizeof(iph), &oph, sizeof(oph), BPF_F_RECOMPUTE_CSUM);
  if(ret < 0)
    value = ret;

  ret = bpf_skb_store_bytes(skb, sizeof(eth) + sizeof(iph) + sizeof(oph), &id, sizeof(id), BPF_F_RECOMPUTE_CSUM);
  if(ret < 0)
    value = ret;

  return TC_ACT_OK;
}
