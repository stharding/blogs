#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
c-shader/02-fragment.py

mandelbrot fragment shader
"""

# imports ####################################################################

from OpenGL.GLUT import *
from OpenGL.GL import *

from math import exp, log, sqrt

from ctypes.util import *

GLUT_WHEEL_UP   = 3
GLUT_WHEEL_DOWN = 4


# shaders ####################################################################

frag_shader_source = """\
vec2 csquare(in vec2 c) {
    return vec2(c.x*c.x-c.y*c.y, 2.*c.x*c.y);
}

uniform int max_i;

int steps(in vec2 c) {
    vec2 z = vec2(0., 0.);
    int i;
    for(i = 0; i < max_i; i++) {
        z = csquare(z) + c;
        if(length(z) > 2.) {
            break;
        }
    }
    return i;
}


uniform sampler1D palette;

void main() {
    vec2 c = gl_TexCoord[0].st;
    int i = steps(c);
    if(i == 0) discard;
    gl_FragColor = texture1D(palette, float(max_i-i)/16.);
}
"""


# constants ##################################################################

WINDOW_SIZE = 640, 480


# display ####################################################################

center = .5, 0.
scale = .5

def reshape(width, height):
    """window reshape callback."""
    glViewport(0, 0, width, height)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    r = float(max(width, height))
    w, h = width/r, height/r
    glOrtho(-w, w, -h, h, -1, 1)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()

def display():
    """window redisplay callback."""
    glClear(GL_COLOR_BUFFER_BIT)
    glBegin(GL_TRIANGLE_STRIP)
    cx, cy = center
    for x in [-1, 1]:
        for y in [-1, 1]:
            glTexCoord(x/scale-cx, y/scale-cy)
            glVertex(x, y)
    glEnd()
    glutSwapBuffers()


# interaction ################################################################

def keyboard(c, x, y):
    """keyboard callback."""
    if c in ["q", chr(27)]:
        sys.exit(0)
    glutPostRedisplay()


panning = False
zooming = False

def mouse(button, state, x, y):
    global x0, y0, panning
    global xz, yz, zooming
    x0, y0 = xz, yz = x, y

    if button == GLUT_LEFT_BUTTON:
        panning = (state == GLUT_DOWN)

    elif button == GLUT_RIGHT_BUTTON:
        zooming = (state == GLUT_DOWN)

    elif button == GLUT_WHEEL_UP:
        zoom(x, y, 1)
    elif button == GLUT_WHEEL_DOWN:
        zoom(x, y, -1)


def motion(x1, y1):
    global x0, y0, panning
    global xz, yz, zooming
    dx, dy = x1-x0, y1-y0
    x0, y0 = x1, y1

    if panning:
        pan(dx, dy)

    elif zooming:
        zoom(xz, yz, dx-dy)


def pan(dx, dy):
    global center, scale
    cx, cy = center
    r = max(glutGet(GLUT_WINDOW_WIDTH), glutGet(GLUT_WINDOW_HEIGHT))
    dx *=  2./r/scale
    dy *= -2./r/scale
    center = cx+dx, cy+dy
    glutPostRedisplay()

def zoom(x, y, s):
    global scale, center

    cx, cy = center
    width, height = glutGet(GLUT_WINDOW_WIDTH), glutGet(GLUT_WINDOW_HEIGHT)
    r = max(width, height)
    x = (2.*x-width)/r/scale
    y = (height-2.*y)/r/scale

    ds = exp(s*.01)
    cx += (x-cx)*(1.-ds)
    cy += (y-cy)*(1.-ds)
    center = cx/ds, cy/ds
    scale *= ds

    glUniform1i(max_i_location, int(4.*(log(scale)/log(2)+1))+32)
    glutPostRedisplay()


# setup ######################################################################

def init_glut(argv):
    """glut initialization."""
    glutInit(argv)
    glutInitDisplayMode(GLUT_RGBA|GLUT_DOUBLE)
    glutInitWindowSize(*WINDOW_SIZE)

    glutCreateWindow(argv[0])

    glutReshapeFunc(reshape)
    glutDisplayFunc(display)
    glutKeyboardFunc(keyboard)
    glutMouseFunc(mouse)
    glutMotionFunc(motion)


def init_opengl():
    # program
    frag_shader = create_shader(frag_shader_source, GL_FRAGMENT_SHADER)
    program = create_program(frag_shader)
    glUseProgram(program)

    global max_i_location
    max_i_location = glGetUniformLocation(program, "max_i")
    glUniform1i(max_i_location, 32)

    # texture
    palette_location = glGetUniformLocation(program, "palette")
    glUniform1i(palette_location, 0)

    glEnable(GL_TEXTURE_1D)
    glActiveTexture(GL_TEXTURE0+0)
    glBindTexture(GL_TEXTURE_1D, glGenTextures(1))
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

    glTexImage1D(GL_TEXTURE_1D, 0, GL_LUMINANCE, 16, 0,
                 GL_LUMINANCE, GL_UNSIGNED_BYTE,
                 "".join(chr(c*16) for c in range(16)))


# main #######################################################################

import sys

def main(argv=None):
    if argv is None:
        argv = sys.argv
    init_glut(argv)
    init_opengl()
    return glutMainLoop()

if __name__ == "__main__":
    sys.exit(main())