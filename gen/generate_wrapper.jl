using Clang
using Clang.Generators
using JuliaFormatter

cd(@__DIR__)

const HEADER_BASE = joinpath(ENV["KNITRODIR"], "include")
const KNITRO_H = joinpath(HEADER_BASE, "knitro.h")

headers = [KNITRO_H]
options = load_options(joinpath(@__DIR__, "generator.toml"))

args = get_default_args()
push!(args, "-I$HEADER_BASE")

ctx = create_context(headers, args, options)
build!(ctx)

path = options["general"]["output_file_path"]
format_file(path, YASStyle())

str = read(path, String)
str =
"""
# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

#!format:off
""" * str *
"""
#!format:on
"""
write(path, str)
