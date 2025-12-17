# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using Clang: Generators
import KNITRO_jll

const HEADER_BASE = joinpath(KNITRO_jll.artifact_dir, "knitro", "include")
const KNITRO_H = joinpath(HEADER_BASE, "knitro.h")

Generators.build!(
    Generators.create_context(
        [KNITRO_H],
        [Generators.get_default_args(); "-I$HEADER_BASE"],
        Generators.load_options(joinpath(@__DIR__, "generator.toml")),
    ),
)
