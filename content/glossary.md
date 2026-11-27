---
cnl: ste
cnl-version: 1
cnl-scope: narrative
lexicon: core-v1
lint: light
---
# Glossary

Terms used across the course, collected in one place. Definitions describe how the words are used here; where a term has a narrower standard definition, that is noted.

**AEAD (authenticated encryption with associated data).** A construction that provides both confidentiality and integrity in one operation, and can authenticate data that is carried alongside the ciphertext but not encrypted. AES-GCM and ChaCha20-Poly1305 are AEAD algorithms. Prefer AEAD over encrypting and authenticating separately.

**Algorithm.** A specific, concrete procedure: the step-by-step operations that turn an input into an output. An algorithm may implement a primitive directly (the AES algorithm implements the AES block cipher), apply a primitive in a mode of operation (AES-GCM), or compose primitives into a higher-level construction (HMAC-SHA256). A primitive is abstract; an algorithm is what actually runs.

**Cipher.** Historically, a complete method for transforming plaintext into ciphertext and back — a Caesar cipher, the Enigma cipher — each a self-contained system. In modern usage the word has drifted downward into shorthand for "cipher algorithm" ("the cipher is AES-256-GCM"). When precision matters, say "cipher algorithm" for the concrete procedure and reserve "cipher" for the historical sense.

**Cipher suite.** A named bundle of algorithm choices that together specify a complete cryptosystem configuration. `TLS_AES_256_GCM_SHA384` names the AEAD for bulk encryption and the hash for key derivation, selecting one concrete cryptosystem from the space TLS 1.3 allows. Endpoints that "negotiate a cipher suite" are choosing which cryptosystem to run for the session.

**Cryptographic primitive.** The smallest building block of cryptographic construction, a single well-defined operation whose security is not reduced to simpler cryptographic parts. Block ciphers (AES), hash functions (SHA-256), signature schemes (Ed25519), key-exchange operations (Diffie–Hellman) and CSPRNGs are primitives. Each rests on assumptions — one-wayness, collision resistance, indistinguishability from random — that are conjectured rather than proven. When an assumption fails, constructions that rely on it must be re-evaluated: DES became insecure through brute force rather than a broken mathematical assumption, while HMAC-SHA1 remains viable in many settings.[^des] [^hmac]

**Cryptosystem.** A complete, deployable scheme that provides a useful security guarantee by composing primitives and algorithms with everything needed to use them: key management, parameter choices, message formats, protocol structure and claimed properties. TLS 1.3, WireGuard, Signal and GPG are cryptosystems. This is where cryptography meets the real world, and where most deployed failures happen — not because a primitive broke, but because it was composed, parameterised or managed wrongly.

**Forward secrecy.** The property that compromise of a long-term key does not expose past session keys. It is obtained by generating fresh, ephemeral key material for each session and discarding it afterwards. WPA3's SAE handshake and TLS 1.3 ephemeral key exchange both provide it.

**Framework.** A template above cryptosystems for constructing families that share a structure, parameterised by the choices made for each instantiation. The Noise Protocol Framework produces concrete cryptosystems (Noise_IK, Noise_XX and others) from handshake patterns and primitive choices; SIGMA is another example. A framework is to cryptosystems what a construction is to algorithms: one level of abstraction up.

**Hard problem.** A computational task believed infeasible to solve in reasonable time with realistic resources, and whose presumed intractability supports a primitive's security. Integer factorisation, discrete logarithm, elliptic-curve discrete logarithm and Learning With Errors are the canonical examples. "Hard" is conjectured, not proven, and is supported by decades of failed attacks. Shor's algorithm makes factoring and discrete logarithm solvable in polynomial time on a sufficiently large quantum computer — feasible, not necessarily quick — which is why the post-quantum transition affects the whole classical public-key stack.[^shor]

**HSM (hardware security module).** A dedicated device that generates and holds keys and performs cryptographic operations without exposing the key material to its host. Its value is the boundary it enforces: a process can request an operation but cannot read the key. A TPM is a narrower form aimed at a single host.

**KDF (key derivation function).** A function that turns a secret and auxiliary input into one or more keys suitable for use. A password-based KDF such as Argon2id or scrypt deliberately costs time and memory to slow guessing; a TLS KDF derives session keys from a shared secret and transcript.

**mTLS (mutual TLS).** TLS in which the server verifies the client's certificate as well as the client verifying the server's. The client's identity is established at the handshake, before application data is exchanged, rather than by a token presented later.

**Protocol.** A specified sequence of messages exchanged between parties, the operations each performs on receipt, and the rules for valid state transitions. "Protocol" and "cryptosystem" are often used interchangeably because most real cryptosystems are protocols and most cryptographic protocols are cryptosystems. "Protocol" emphasises message exchange and state; "cryptosystem" emphasises composition and guarantees. TLS 1.3 is both.

[^des]: National Institute of Standards and Technology, *Data Encryption Standard (DES)*, FIPS 46-3, withdrawn 2005.
[^hmac]: Hugo Krawczyk, Ran Canetti and Mihir Bellare, “HMAC: Keyed-Hashing for Message Authentication,” RFC 2104, 1997.
[^shor]: Peter W. Shor, “Algorithms for Quantum Computation: Discrete Logarithms and Factoring,” *Proceedings of the 35th Annual Symposium on Foundations of Computer Science*, 1994.
