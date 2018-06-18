A Ray Tracing Adventure
=======================


I've been entertaining the idea of writing a ray tracer for a while now and last weekend I stumbled across the excellent book "Ray Tracing in One Weekend" by Peter Shirley. I really enjoyed the read and had even more fun following along and implementing it.

I dismissed Peter's advise to write it in C++ and instead did a Cython implementation. The total implementation is 575 SLOC (excluding whitespace).

I won't go into all the details of writing the ray tracer (if you are interested, read the book---it's really accessible and it is only 49 pages). I will however say that after writing the code, it was also interesting to profile the code and find the places where small syntax changes made *huge* differences in runtime. When a function is executed many millions of times, even small alterations make a big difference. That said, there is still plenty of room for improvement.

My implementation is on github [here](https://github.com/stharding/ray_tracing).

This is the scene you render at the end if you follow along in the book:

![ray-traced-img](https://www.themetabytes.com/wp-content/uploads/2018/06/1920x1080-ray.png)

