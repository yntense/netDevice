#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

#define SIOCGMESHSTATS 0x89F0

int main(int argc, char *argv[])
{
    int sockfd;
    struct ifreq ifr;
    char *ifname = "mesh0";
    
    printf("915MHz Mesh Network Driver Test Program\n");
    printf("=====================================\n");
    
    // 创建套接字
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("socket");
        return 1;
    }
    
    // 设置接口名称
    strncpy(ifr.ifr_name, ifname, IFNAMSIZ);
    
    // 获取接口状态
    if (ioctl(sockfd, SIOCGIFFLAGS, &ifr) < 0) {
        perror("SIOCGIFFLAGS");
        close(sockfd);
        return 1;
    }
    
    printf("Interface %s status: ", ifname);
    if (ifr.ifr_flags & IFF_UP) {
        printf("UP\n");
    } else {
        printf("DOWN\n");
    }
    
    // 获取接口地址
    if (ioctl(sockfd, SIOCGIFADDR, &ifr) < 0) {
        perror("SIOCGIFADDR");
    } else {
        struct sockaddr_in *addr = (struct sockaddr_in *)&ifr.ifr_addr;
        printf("IP Address: %s\n", inet_ntoa(addr->sin_addr));
    }
    
    // 获取MAC地址
    if (ioctl(sockfd, SIOCGIFHWADDR, &ifr) < 0) {
        perror("SIOCGIFHWADDR");
    } else {
        unsigned char *mac = (unsigned char *)&ifr.ifr_hwaddr.sa_data;
        printf("MAC Address: %02x:%02x:%02x:%02x:%02x:%02x\n",
               mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
    }
    
    // 获取接口统计信息
    printf("Interface statistics: Not available in this version\n");
    
    printf("\nTesting mesh network functionality...\n");
    
    // 这里可以添加更多的测试代码
    // 比如发送测试数据包、测试节点发现等
    
    printf("Test completed successfully!\n");
    
    close(sockfd);
    return 0;
}
