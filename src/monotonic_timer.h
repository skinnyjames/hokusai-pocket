// Copyright 2013 Alex Reece.
// https://github.com/awreece/monotonic_timer/blob/master/monotonic_timer.h
//
// A cross platform monotonic timer.

#ifndef MONOTONIC_TIMER_H_
#define MONOTONIC_TIMER_H_

// Returns seconds since some unspecified start time (guaranteed to be
// monotonicly increasing).
double monotonic_seconds();

#endif  // MONOTONIC_TIMER_H_