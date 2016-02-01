//
//  csockets.c
//  Connection
//
//  Created by Kevin Musselman on 1/29/16.
//  Copyright © 2016 Pilot Foundation. All rights reserved.
//

#include "csockets.h"


#include <fcntl.h>
#include <sys/ioctl.h>

int ari_fcntlVi(int fildes, int cmd, int val) {
    return fcntl(fildes, cmd, val);
}

int ari_ioctlVip(int fildes, unsigned long request, int *val) {
    return ioctl(fildes, request, val);
}