## Layer 0 - Physics

### Introduction

All networking is physics. Below any frame, packet, or byte, something physical moves: electrons oscillating in copper, photons travelling through glass, electromagnetic waves propagating through air, pressure waves in water for subsea links. This is the pure signal, energy in motion through a medium, and it exists before anything interprets it.

**At this layer, nothing is yet a bit.** There is voltage on a wire, light intensity in a fibre core, electromagnetic wave amplitude and phase in air. These are continuous, analogue phenomena. The decision to treat a particular voltage level as a 1 or a 0, or a particular light pulse as one symbol in a coding scheme, is made by the layer above. Below that decision, the network is pure energy moving through matter.

Understanding this matters because everything above this layer inherits the physics of the signal itself. The higher layers make promises, that data arrived correctly, that nobody read it in transit, that the session is authenticated, that physics has to keep. When the physical reality of the signal is treated as invisible, architects build on assumptions the physics cannot actually support.

For a security architect, three properties of the signal matter most: **signal strength**, **interference**, and **emanation**. The first two determine whether communication is possible at all. The third determines whether anyone else can hear it.

### Signal strength and attenuation

A signal is energy, and energy dissipates as it travels. This is attenuation, and it is unavoidable in every medium.

In copper, electrical energy weakens because the wire has resistance, some of the signal is lost as heat, and because at high frequencies current flows only near the surface of the conductor, effectively reducing its capacity. In fibre, light dims because glass is not perfectly transparent, and because microscopic imperfections scatter photons out of the intended path. In air, electromagnetic waves spread out as they propagate, and are absorbed or deflected by water vapour, walls, bodies, furniture, and other obstacles.

Every medium has a practical range beyond which the signal is too weak to recover usable information. For Cat 6, this is around 100 metres. For single-mode fibre, it can be tens of kilometres. For WiFi in the 5 GHz band, it might be one or two rooms of a typical building. These numbers aren't arbitrary, they correspond to the point at which the surviving signal can no longer be distinguished from the noise around it.

The architectural consequence is that **distance and environment constrain where equipment can go**. A secure design respects the physical reach of each medium it depends on. Extending beyond that reach requires repeaters, switches, or media conversion, each of which introduces a new component into the trust boundary.

### Interference

While a signal travels, the medium around it is full of other energy. A copper cable near fluorescent lights picks up electromagnetic noise from the ballasts. A WiFi signal competes with microwave ovens, Bluetooth devices, neighbouring access points, and bleed from poorly shielded electronics. Fibre is the quietest medium, glass cores don't couple to external EM fields, but even fibre experiences dispersion at high signalling rates, where different wavelengths arrive at slightly different times and blur the boundary between one transmitted symbol and the next.

The metric that matters is not signal strength alone but the **ratio of signal to noise**. A strong signal in a noisy environment can fail to be recovered; a weak signal in a quiet environment can still be usable. Every receiver has a threshold below which this ratio collapses and information is lost.

When the ratio degrades, networks do not usually fail cleanly. They slow down. Retransmissions occur at higher layers, congestion-control algorithms back off, latency climbs, throughput collapses. This kind of degradation is often misdiagnosed up the stack, it looks like an application problem or a server issue, when the underlying cause is radio noise or electrical interference at the medium.

Interference is not only accidental. An attacker can deliberately create it. **Jamming**, flooding a radio band with noise, is a physical-layer denial of service that no amount of encryption above can defeat. A cheap 2.4 GHz jammer can take a WiFi network offline within its range; a directional jammer can target a specific link from outside a building. This defines the boundary of what upper-layer security can protect. Everything above the physical medium assumes the medium is working. If the physics fails, nothing above runs.

### Emanation

Every signal transmitted radiates energy beyond the intended path. This is the security property of the physical layer most often forgotten.

Copper cables emit weak electromagnetic fields that can be picked up with sensitive equipment at surprising distances, the TEMPEST problem, studied and classified by governments since the 1950s. The signal radiating from a poorly shielded Ethernet cable or a video display is, physically, a broadcast; it can be captured by anyone with the right receiver in range.

WiFi and cellular signals are broadcasts by design. Every transmission from an access point fills a volume of space with energy that carries the signal, and anyone within that volume, with an appropriate antenna and receiver, can capture it. There is no physical defence against this capture; the only defence is that the signal, once captured and decoded into symbols by the attacker's equipment, is cryptographically protected by a layer above.

Fibre is the best of the three in this respect. Light remains inside the glass core. Passive interception requires splicing into the fibre itself, which introduces a detectable disturbance in the signal. Physical access to the cable run is the attack surface.

This yields a rough interception-surface ranking:

- **Wireless**, any receiver in range can capture the signal passively. Range depends on frequency and antenna, and with a directional antenna can be hundreds of metres.
- **Copper**, signal emanates as an electromagnetic field. With shielded cable and proper grounding the useful range is short; with unshielded cable a determined adversary can read signals from tens of metres.
- **Fibre**, no significant emanation. Interception requires physical access to the cable.

The architectural consequence is that **where the cable goes is a security decision**. A fibre run through a controlled ceiling plenum is far more defensible than a copper run along an exterior wall shared with a neighbouring tenant. WiFi that spills into a parking lot exposes its signal to anyone willing to sit there with a laptop. Medium selection and medium placement belong in the threat model alongside firewall rules and identity policies.

### Why this matters for the rest of the course

Everything above this layer makes promises that the physics has to keep. A TLS handshake assumes the underlying signal is being decoded into the symbols that carry the handshake. A VLAN assumes no adversary is reading the cable physically. An 802.1X authentication assumes the radio is not being jammed, spoofed, or cloned.

Three realities should remain unforgettable:

1. Signals weaken with distance and environment, which constrains where equipment can physically go.
2. Noise is sometimes natural and sometimes deliberate, and it degrades the network before it kills it.
3. Signals radiate beyond their intended path, and the medium chosen determines who can hear them.

Every higher layer inherits these realities. A secure architecture acknowledges the physics and designs around it rather than assuming the medium into invisibility.
