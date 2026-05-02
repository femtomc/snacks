---
description: "Citing papers, linking prior work, looking up external sources"
---

# References

High-value links and citations, organized by theme. Each entry is one line so
you can judge relevance without fetching.

## Syndicated Actor Model — primary

- Garnock-Jones, [_Conversational Concurrency_](https://syndicate-lang.org/tonyg-dissertation/html/)
  (PhD, Northeastern, 2017). [PDF](https://arxiv.org/abs/2409.04055). The
  foundational text. Ch 2: Gricean maxims as protocol design tests; three kinds
  of knowledge + interests; six design principles. Ch 3: survey of coordination
  approaches and 12 design criteria. Ch 4: formal dataspace model — bag
  semantics with set-level visibility, patches, assertion tries; Theorem 4.35
  (bag-to-set soundness). Ch 5: Syndicate/lambda — facets, fields, endpoints,
  spawn, `during`, 14 reduction rules. Ch 7: trie-based assertion index. Ch 8:
  idiomatic patterns. Ch 9: pattern elimination evaluation.
- Caldwell, Garnock-Jones & Felleisen,
  [_Conversational Concurrency with Dataspaces and Facets_](https://doi.org/10.22152/programming-journal.org/2025/10/2)
  (Programming 10(1), 2025). Mature presentation of the full SAM programming
  model — best single reference for the model as Tiny implements it.
- Caldwell, [_Reasoning about Actors that Share State_](https://doi.org/10.17760/d20560782)
  (PhD, Northeastern, 2023). [PDF](https://repository.library.northeastern.edu/files/neu:4f214s28h/fulltext.pdf).
  Three-layer type architecture: structural (shape errors in shared
  assertions), behavioral (LTL), effect (assertion effects per facet).
  Operational semantics at the type level enables LTL model checking.
- Caldwell, Garnock-Jones & Felleisen,
  [_Typed Dataspace Actors_](https://doi.org/10.1017/s0956796820000246)
  (JFP 30, 2020). The structural type layer.
- Caldwell, Garnock-Jones & Felleisen,
  [_Programming and Reasoning About Actors That Share State_](https://doi.org/10.1017/s0956796824000091)
  (JFP 34, 2024). Journal version of the dissertation; behavioral and effect
  type layers on the structural foundation.
- Garnock-Jones & Felleisen,
  [_Coordinated Concurrent Programming in Syndicate_](https://doi.org/10.1007/978-3-662-49498-1_13)
  (ESOP 2016). The conference paper.
- Garnock-Jones, [_From Events to Reactions: A Progress Report_](https://doi.org/10.4204/eptcs.211.5)
  (EPTCS 211, 2016). Evolution from event-driven to assertion-driven.
- Garnock-Jones, Tobin-Hochstadt & Felleisen,
  [_The Network as a Language Construct_](https://doi.org/10.1007/978-3-642-54833-8_25)
  (ESOP 2014). Early precursor — the network as scoped broadcast.

## Syndicated Actor Model — implementations

- [Syndicate project](https://syndicate-lang.org/) — landing page.
- [syndicate-rs](https://git.syndicate-lang.org/syndicate-lang/syndicate-rs)
  (Rust) — the primary implementation reference for Tiny's formal model
  (~11K lines). Workspace: `syndicate` (core), `syndicate-server` (broker),
  `syndicate-macros` (`during!`/`template!`), `syndicate-tools`,
  `syndicate-schema-plugin`. Key modules: `actor.rs` (Entity, Cap, Ref,
  Activation/Turn, Facet, Field, Account — 2600 lines), `bag.rs` (BTreeBag),
  `dataspace.rs` (skeleton + handle map, ~95 lines), `skeleton.rs` (trie
  index, 500 lines), `during.rs`, `relay.rs` (TunnelRelay, Membrane, OID
  mapping, 926 lines), `sturdy.rs` (HMAC-Blake2s SturdyRef), `rewrite.rs`
  (caveat attenuation), `dataflow.rs`, `pattern.rs`, `trace.rs`. Server:
  gatekeeper, daemon supervisor, config_watcher, TCP/Unix/WebSocket relays,
  HTTP router. Lean/Python/Zig ports align module-by-module.
- [syndicate-rkt](https://github.com/tonyg/syndicate) (Racket) — original
  implementation. Useful for the original surface syntax and macro-expansion
  model.

## Synit — SAM as infrastructure OS

- [Synit manual](https://git.syndicate-lang.org/synit/synit-manual). SAM
  applied to system management. Replaces systemd + D-Bus + NetworkManager with
  a single dataspace bus. Config files are `.pr` Preserves assertions. Service
  lifecycle is reactive (`<require-service>`, `<depends-on>`,
  `<run-service>`, `<service-state>`) — no scheduler, no topo sort.
- [Synit glossary](https://synit.org/book/glossary.html). SAM terminology.
- [Synit: SAM](https://synit.org/book/syndicated-actor-model.html). Concise
  description from the Synit perspective.
- [Synit source](https://git.syndicate-lang.org/synit/). `synit-pid1`
  (minimal Rust PID 1) + `syndicate-server` (system bus). Config layers in
  `/etc/syndicate/`. Schemas in `.prs` files. NLnet/NGI Zero funded.

## Preserves — data model

- [Preserves spec](https://preserves.dev/). Data model for all
  Syndicate/Synit/Tiny protocols. Atoms (Boolean, SignedInteger, Double,
  String, ByteString, Symbol), compounds (Record, Sequence, Set, Dictionary),
  Embedded (capabilities). Records `<label field1 field2>` are the primary
  protocol structure. Total ordering across all values. Three wire formats:
  text, binary, Syrup. Self-describing.

## Rhombus and shrubbery — surface syntax

- [Rhombus docs](https://docs.racket-lang.org/rhombus/index.html). Tiny's
  frontend (lexer/parser, enforester, precedence, macros) is modeled on
  Rhombus. Indentation grouping via `:` and `\|`, enforestation, multi-space
  dispatch (expr, defn, bind).
- Flatt, [_Binding as Sets of Scopes_](https://doi.org/10.1145/2837614.2837620)
  (POPL 2016). The macro hygiene model. Bindings keyed by name + scope set;
  references resolve to the binding whose scope set is the largest subset.
  Tiny's `syntax.py`, `enforest/hygiene.py`, `enforest/syntax_meta.py`
  implement this directly. §3.5 covers use-site scopes preventing accidental
  capture.
- Flatt et al., _Rhombus: A New Spin on Macros without All the Parentheses_
  (OOPSLA 2023). Full synthesis: shrubbery + enforestation + scope-set
  hygiene + multiple binding spaces + static information protocol. Precedence
  is relational (pairwise, non-transitive), not numeric.
- Rafkind & Flatt, _Honu: Syntactic Extension for Algebraic Notation through
  Enforestation_ (GPCE 2012). Pratt-style precedence parsing interleaved with
  macro expansion. Tiny's `enforest/enforest.py` implements it.

## Actor model — foundations

- Hewitt, Bishop & Steiger, [_A Universal Modular ACTOR Formalism_](https://www.ijcai.org/Proceedings/73/Papers/027.pdf)
  (IJCAI 1973). Original actor paper. Create, send, become.
- Agha, _Actors_ (MIT Press, 1986). Canonical actor monograph.
- Clinger, [_Foundations of Actor Semantics_](https://dspace.mit.edu/bitstream/handle/1721.1/6935/AITR-633.pdf)
  (PhD, MIT, 1981). Denotational semantics of actors via power domains.
- Agha, Mason, Smith & Talcott, [_A Foundation for Actor Computation_](https://doi.org/10.1017/s095679689700261x)
  (JFP 7(1), 1997). Operational semantics for open actor systems.
- De Koster, Van Cutsem & De Meuter, [_43 Years of Actors_](https://doi.org/10.1145/3001886.3001890)
  (AGERE! 2016). Taxonomy: classic actors, active objects, processes,
  communicating event-loops.
- De Boer et al., [_A Survey of Active Object Languages_](https://doi.org/10.1145/3122848)
  (CSUR 50(5), 2017).
- Armstrong, [_Making Reliable Distributed Systems_](https://erlang.org/download/armstrong_thesis_2003.pdf)
  (PhD, KTH, 2003). Erlang/OTP: let it crash, supervision trees.
- Armstrong, [_A History of Erlang_](https://doi.org/10.1145/1238844.1238850)
  (HOPL III, 2007).

## Coordination languages and tuplespaces

- Gelernter, [_Generative Communication in Linda_](https://doi.org/10.1145/2363.2433)
  (TOPLAS 7(1), 1985). `out`/`in`/`rd` tuplespace coordination. Tuples persist
  after creator exits — the key difference from Syndicate's non-generative
  assertions.
- Gelernter & Carriero, [_Coordination Languages and Their Significance_](https://doi.org/10.1145/129630.129635)
  (CACM 35(2), 1992). Coordination orthogonal to computation.
- Mostinckx, Scholliers & De Meuter, [_Fact Spaces_](https://doi.org/10.1007/978-3-540-72794-1_15)
  (COORDINATION 2007). Most direct precursor to dataspaces. Garnock-Jones
  describes dataspaces as "an adaptation and integration of the fact space
  model."
- Callsen & Agha, [_ActorSpace_](https://doi.org/10.1006/jpdc.1994.1060)
  (JPDC 21(3), 1994). Closest actor-tradition precursor. Pattern-directed
  group communication — but routes messages, not assertions.
- Carvalho, [_Our AI Orchestration Frameworks Are Reinventing Linda_](https://otavio.cat/posts/ai-orchestration-reinventing-linda/)
  (2025). Argues LangChain/AutoGen/CrewAI rediscover tuplespace coordination.

## Capability security

- Miller, [_Robust Composition_](http://www.erights.org/talks/thesis/) (PhD,
  Johns Hopkins, 2006). Defines the ocap discipline: no ambient authority,
  unforgeable references, authority flows with reference passing.
- Swasey, Garg & Dreyer, [_Robust and Compositional Verification of Object
  Capability Patterns_](https://doi.org/10.1145/3133913) (OOPSLA 2017). Iris
  formalization.
- Birgisson et al., [_Macaroons_](https://doi.org/10.14722/ndss.2014.23212)
  (NDSS 2014). HMAC-chained caveats. Syndicate's SturdyRef attenuation uses
  this model.
- Dennis & Van Horn, [_Programming Semantics for Multiprogrammed Computations_](https://doi.org/10.1145/365230.365252)
  (CACM 9(3), 1966). Origin of capability-based addressing.

## Verification frameworks

- Jung et al., [_Iris from the Ground Up_](https://doi.org/10.1017/S0956796818000151)
  (JFP 28, 2018). Higher-order concurrent separation logic. Resource
  algebras unify ghost state, invariants, frame-preserving updates. Resource
  algebras map to assertion ownership in dataspaces.
- Hinrichsen, Bengtson & Krebbers, [_Actris_](https://doi.org/10.1145/3371074)
  (POPL 2020). Iris + dependent separation protocols (session types). Closest
  framework to dataspace protocol verification — but Actris is point-to-point
  while Syndicate is pub/sub.
- Jung et al., [_RustBelt_](https://doi.org/10.1145/3158154) (POPL 2018).
  Semantic type soundness for Rust via Iris. Assertion lifetime ↔ borrow
  lifetime; viable approach for Tiny's static type system.

## Process calculi and session types

- Hoare, [_Communicating Sequential Processes_](https://doi.org/10.1145/359576.359585)
  (CACM 21(8), 1978). Algebraic laws for parallel composition, hiding,
  refinement.
- Milner, _Communicating and Mobile Systems: the Pi-Calculus_ (CUP, 1999).
  Name-passing, scope extrusion.
- Fournet & Gonthier, [_The Reflexive CHAM and the Join-Calculus_](https://doi.org/10.1145/237721.237805)
  (POPL 1996). Influenced Syndicate's assertion-matching.
- Honda, Yoshida & Carbone, [_Multiparty Asynchronous Session Types_](https://doi.org/10.1145/2827695)
  (JACM 63(1), 2016).
- Caires & Vieira, [_Conversation Types_](https://doi.org/10.1016/j.tcs.2010.09.010)
  (TCS 411, 2010). Multi-party conversations with join/leave.
- Fowler, [_Model-View-Update-Communicate_](https://doi.org/10.4230/LIPIcs.ECOOP.2020.14)
  (ECOOP 2020). Session types meet Elm — relevant to Tiny's REPL.

## Reactive programming

- Elliott & Hudak, [_Functional Reactive Animation_](https://doi.org/10.1145/258949.258973)
  (ICFP 1997). The original FRP paper.
- Czaplicki & Chong, _Asynchronous FRP for GUIs_ (PLDI 2013). Elm — discrete
  FRP with signals and mailboxes.
- Salvaneschi, Hinze & Mezini, _REScala_ (Modularity 2014). Bridging OO and
  FRP.
- Mandel & Pouzet, _ReactiveML_ (PPDP 2005). Synchronous reactive ML.
- Van den Vonder et al., [_The Actor-Reactor Model_](https://doi.org/10.4230/LIPIcs.ECOOP.2020.9)
  (ECOOP 2020). Async actors + sync dataflow — direct comparison for
  Syndicate's combined assertion/message model.
- Bainomugisha et al., [_A Survey on Reactive Programming_](https://doi.org/10.1145/2501654.2501666)
  (CSUR 45(4), 2013).

## Effects and monads

- Moggi, _Notions of Computation and Monads_ (I&C 93(1), 1991). Tiny's formal
  model (P0) uses a monadic core.
- Plotkin & Power, _Notions of Computation Determine Monads_ (FoSSaCS 2002).
  Algebraic effects.
- Plotkin & Pretnar, _Handlers of Algebraic Effects_ (ESOP 2009).

## Distributed systems and fault tolerance

- De Groen & Garnock-Jones, [_Fine-grained Fault Tolerance in Distributed
  Training Toolkits using SAM_](https://doi.org/10.1145/3774902.3776630)
  (MIND 2025). Workers assert state into a shared dataspace; on crash,
  assertions retract automatically and the coordinator reassigns only the
  failed shard. TF/PyTorch abort all jobs on any worker failure.
- Clark, [_The Design Philosophy of the DARPA Internet Protocols_](https://doi.org/10.1145/52324.52336)
  (SIGCOMM 1988). Fate sharing — directly motivates non-generative
  assertions.
- Saltzer, Reed & Clark, [_End-to-End Arguments_](https://doi.org/10.1145/357401.357402)
  (TOCS 2(4), 1984). Policy in actors, not in the dataspace mechanism.
- Alvaro et al., [_CALM_](https://dsf.berkeley.edu/papers/cidr11-bloom.pdf)
  (CIDR 2011). Monotonic programs are eventually consistent without
  coordination.
- Sustrik, [_Structured Concurrency_](https://www.250bpm.com/p/structured-concurrency)
  (2016). Concurrent operations form a tree, child lifetimes bounded by
  parent — realized by Syndicate's facets.

## OS and systems architecture

- Engler, Kaashoek & O'Toole, _Exokernel_ (SOSP 1995). Minimal kernel exposes
  hardware, push policy to user-space. Analogy: minimal SAM kernel, push agent
  policy to user space.
- Klein et al., _seL4_ (SOSP 2009). Machine-checked microkernel proof.
  Parallel to Tiny's formally verified SAM kernel.

## LLM agent frameworks (comparison points)

- Chase, [LangChain](https://github.com/langchain-ai/langchain) (2022).
  Imperative chains vs Tiny's declarative assertion-based coordination.
- Wu et al., _AutoGen_ (arXiv:2308.08155, 2023). Multi-agent framework with
  controller-mediated message passing.
- Microsoft, [Semantic Kernel](https://learn.microsoft.com/en-us/semantic-kernel/overview/)
  (2023). Plugin-based orchestration.
- Yao et al., _ReAct_ (ICLR 2023). The reason-act loop.
- Beurer-Kellner et al., _LMQL_ (PACMPL 7(PLDI), 2023). Constrained decoding.
- Packer et al., _MemGPT_ (NeurIPS Workshop 2023). LLM-as-OS with memory
  management.
- Khattab et al., _DSPy_ (ICLR 2024). Declarative LM pipelines with prompt
  optimization.
- Zheng et al., _SGLang_ (NeurIPS 2024). Structured LM execution, batching.

## Historical and foundational

- Dahl & Nygaard, _SIMULA_ (CACM 9(9), 1966). First OO language. Coroutines.
- Kay, _The Early History of Smalltalk_ (HOPL II, 1993). Message-passing OOP.
- Reppy, [_CML_](https://doi.org/10.1145/113445.113470) (PLDI 1991).
  First-class synchronous events.
- Berry & Boudol, _The Chemical Abstract Machine_ (TCS 96(1), 1992). Multiset
  rewriting; influenced Join Calculus.
- Felleisen et al., [_A Functional I/O System_](https://doi.org/10.1145/1596550.1596561)
  (ICFP 2009). World-passing I/O. Precursor to Syndicate's state-centric
  model.
- Grice, [_Logic and Conversation_](https://web.stanford.edu/class/psych205/papers/Grice-1975.pdf)
  (1975). The four maxims — Garnock-Jones uses these as protocol design
  tests.
- Gamma et al., _Design Patterns_ (Addison-Wesley, 1995). Syndicate's
  observation is Observer with crash cleanup and set semantics.
- Nii, [_Blackboard Systems_](https://doi.org/10.1609/aimag.v7i2.537) (AI
  Magazine 7(2), 1986). Shared workspace with opportunistic knowledge sources.
- Eugster et al., [_The Many Faces of Publish/Subscribe_](https://doi.org/10.1145/857076.857078)
  (CSUR 35(2), 2003). Topic/content/type taxonomy. Syndicate subsumes all
  three via pattern-based assertion matching.
- Fagin et al., _Reasoning about Knowledge_ (MIT Press, 2004). Epistemic
  logic. Backdrop for the "three kinds of knowledge."
- Cardelli & Gordon, _Mobile Ambients_ (TCS 240(1), 2000). Scoped, nested
  computation boundaries.

## Flexibility and language design

- Hanson & Sussman, _Software Design for Flexibility_ (MIT Press, 2021).
  Combinators, wrappers, generic dispatch, propagation, degeneracy. The
  additive principle.
- Sussman, _Building Robust Systems_ (2007). Biological motivation for
  degeneracy.
- Radul & Sussman, _The Art of the Propagator_ (2009). Cells accumulate
  partial information. Merge: commutative, associative, idempotent,
  monotonic.
- Abelson & Sussman, _SICP_ (1985). Metalinguistic abstraction.
- Van Cutsem et al., _AmbientTalk_ (SCCC 2007). VUB lineage to fact spaces to
  dataspaces.

## Testing

- MacIver, [Hypothesis docs](https://hypothesis.readthedocs.io/). Typed choice
  sequences unify generation and shrinking.
- Hughes & Claessen, [_QuickCheck_](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)
  (ICFP 2000). Foundational PBT.
- Hughes, [_Testing the Hard Stuff and Staying Sane_](https://www.youtube.com/watch?v=zi0rHwfiX1Q).
  Erlang QuickCheck on distributed databases.
- Hebert, [PropEr Testing](https://propertesting.com/). Stateful + targeted
  PBT for Erlang/OTP.
- Barr et al., [_The Oracle Problem_](https://ieeexplore.ieee.org/document/6963470)
  (TSE 2015). Differential testing as a solution.
- Lamport, _Specifying Systems_. TLA+ as testable spec.

## Language tooling

- [Zig 0.15.0 Reference](https://ziglang.org/documentation/0.15.0/) — current
  target.
- [Zig 0.15.0 Std](https://ziglang.org/documentation/0.15.0/std/).
- [Zig 0.15.1 Release Notes](https://ziglang.org/download/0.15.1/release-notes.html)
  — migration from 0.14.
- [Theorem Proving in Lean 4](https://lean-lang.org/theorem_proving_in_lean4/).
- [Lean 4 Reference](https://lean-lang.org/doc/reference/latest/) — including
  `grind`.
- [Mathematics in Lean](https://leanprover-community.github.io/mathematics_in_lean/).
- [Lean community simp guide](https://leanprover-community.github.io/extras/simp.html).
