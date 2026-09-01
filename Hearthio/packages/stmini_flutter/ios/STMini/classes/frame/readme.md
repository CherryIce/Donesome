#  HLFrame

图片icon尺寸
导航栏 44
tabbar 45
tool 110

打开H5时，H5界面的导航栏和宿主容器是统一的，导航栏样式由宿主容器控制
打开小程序时，小程序界面的导航栏是独立的，由小程序打开H5，H5界面的导航栏和小程序容器是统一的，导航栏样式由小程序容器控制

调用原生
{ 
"method": "必须", 
"params": 
{ 
"msg": "", 
"mode": 0, 
"duration": 2, 
"location": 0 
} 
}

原生回调
{ 
"code": 必须,  "0"成功，"1"失败
"msg": "必须", 
}

Question 
1.结构体初始化后不能直接改变内部变量的值，会报错Cannot assign to property: function call returns immutable value，所以结构体不适合用来作为数据传递的对象(比如HLWebCommonConfig、HLWebInfoStorage)，因为传递过程中是无法再次修改内部属性的值的
