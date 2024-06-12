/*
 * Copyright (C) 2024 Xiaomi Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <libavb.h>

#include "avb_verify.h"

int main(int argc, char* argv[])
{
    int ret;

    if (argc < 3) {
        avb_printf("%s <partition> <key> [suffix]\n", argv[0]);
        return 100;
    }

    ret = avb_verify(argv[1], argv[2], argv[3]);
    if (ret != 0)
        avb_printf("%s error %d\n", argv[0], ret);

    return ret;
}
