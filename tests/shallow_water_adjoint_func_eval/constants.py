from math import sin, cos, pi
import numpy

d0 = 5.5
theta = 0.5
h = 1.0
functional = 0.5
dfunctional = 1
g = 9.81

def eta_src(x, t):
  return 2*pi*d0*cos(2*pi*x)
def u_src(x, t):
  return numpy.array([2*pi*g*cos(2*pi*x)+1,0,0])

def u_exact(x, t):
  return numpy.array([sin(2*pi*x)+t, 0.0, 0.0])

def eta_exact(x, t):
  return sin(2*pi*x)
