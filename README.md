#ShYCache  
###关于ShYCache  
包含的是公司项目使用的缓存方案，主要内容在ShYCacheManage类中。  
这套缓存方案处理了两种类型的缓存：  
1、Local类型缓存：缓存数据过期时间由客户端本地决定  
2、Server类型缓存：缓存数据过期时间由服务器决定  

###Local类型缓存的处理过程  
每次获取数据时先判断本地缓存是否过期，未过期则展示本地缓存，过期则重新请求接口获取数据。  

###Server类型缓存的处理过程  
每次获取数据时先判断本地是否有缓存，有本地缓存则先展示本地缓存，同时再异步请求接口，将本地缓存的生成时间传给服务器。服务器判断缓存是否过期后，返回指令和数据，客户端收到响应后根据指令刷新页面数据或者保持展示本地缓存数据。  

###演示  
1、第一次进入功能页面时，Local类型接口和Server类型接口都需要去服务器取数据：  
![](https://github.com/ShayneYeorg/ShYCache/blob/master/images/1_first_load.gif)  

2、Local类型接口和Server类型接口都有本地缓存并且缓存未过期的情况下，进入功能页面时，直接展示本地缓存：  
（其实Server类型接口还有一个异步请求接口去服务器上校验本地缓存是否过期的操作，只是因为缓存未过期，所以页面没有变动）  
![](https://github.com/ShayneYeorg/ShYCache/blob/master/images/2_read_cache.gif)    

3、Local类型缓存过期的情况下，进入功能页时，接口会重新请求数据：  
![](https://github.com/ShayneYeorg/ShYCache/blob/master/images/3_local_type_expire.gif)   

4、Server类型缓存过期的情况下，进入功能页时，页面首先展示本地缓存数据。在异步调取接口去服务器上校验本地缓存是否过期之后，服务器返回新数据，页面刷新展示新数据：  
![](https://github.com/ShayneYeorg/ShYCache/blob/master/images/4_server_type_expire.gif)   

5、Local类型接口和Server类型接口都有本地缓存并且缓存未过期的情况下，进入功能页面后通过刷新操作触发接口请求，会取下最新的服务器数据进行展示：  
![](https://github.com/ShayneYeorg/ShYCache/blob/master/images/5_refresh_load.gif)   


