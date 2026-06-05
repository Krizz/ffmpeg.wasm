/*
 * Copyright (c) 2018-2025 - softworkz
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

/*
 * ffmpeg.wasm: stub implementation of the filtergraph printing feature.
 *
 * The upstream graphprint.c renders the filtergraph as HTML/Mermaid by
 * embedding compressed CSS/HTML templates via the fftools "resource manager"
 * (fftools/resources/resman.c + generated graph.{html,css}.c). That codegen
 * step is part of FFmpeg's own Makefile and is not run by the emcc-based
 * ffmpeg.wasm build. The feature is only reachable through the -print_graphs /
 * -print_graphs_file CLI options, which ffmpeg.wasm users never pass, so we
 * stub the two entry points out and drop the resman dependency entirely.
 */

#include "graph/graphprint.h"
#include "libavutil/error.h"
#include "libavutil/log.h"

int print_filtergraphs(FilterGraph **graphs, int nb_graphs,
                       InputFile **ifiles, int nb_ifiles,
                       OutputFile **ofiles, int nb_ofiles)
{
    av_log(NULL, AV_LOG_WARNING,
           "-print_graphs is not supported in this ffmpeg.wasm build.\n");
    return AVERROR(ENOSYS);
}

int print_filtergraph(FilterGraph *fg, AVFilterGraph *graph)
{
    return 0;
}
