//
//  csockets.h
//  Connection
//
//  Created by Kevin Musselman on 1/29/16.
//  Copyright © 2016 Pilot Foundation. All rights reserved.
//


#ifndef csockets_h
#define csockets_h


#include <stdio.h>

int ari_fcntlVi(int fildes, int cmd, int val);

int ari_ioctlVip(int fildes, unsigned long request, int *val);

#endif /* csockets_h */
