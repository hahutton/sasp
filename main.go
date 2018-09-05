// Copyright © 2018 Hays Hutton <hays.hutton@gmail.com>
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import "github.com/google/tcpproxy"
import "net"
import "os"
import jww "github.com/spf13/jwalterweatherman"

func main() {
	ips, err := net.LookupIP("nattest.database.windows.net")
	if err != nil {
		jww.ERROR.Println("bad lookup")
		os.Exit(1)
	}
	var p tcpproxy.Proxy
	var ip = ips[0].String()
	jww.INFO.Println(ip)
	p.AddRoute(":1433", tcpproxy.To(ip)) // fallback
	p.Run()
}
