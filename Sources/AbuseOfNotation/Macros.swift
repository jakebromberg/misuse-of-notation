@attached(peer, names: arbitrary)
public macro ProductConformance(_ multiplier: Int) = #externalMacro(module: "AbuseOfNotationMacros", type: "ProductConformanceMacro")

@attached(member, names: arbitrary)
public macro FibonacciProof(upTo n: Int) = #externalMacro(module: "AbuseOfNotationMacros", type: "FibonacciProofMacro")

@attached(member, names: arbitrary)
public macro PiConvergenceProof(depth n: Int) = #externalMacro(module: "AbuseOfNotationMacros", type: "PiConvergenceProofMacro")

@attached(member, names: arbitrary)
public macro GoldenRatioProof(depth n: Int) = #externalMacro(module: "AbuseOfNotationMacros", type: "GoldenRatioProofMacro")

@attached(member, names: arbitrary)
public macro Sqrt2ConvergenceProof(depth n: Int) = #externalMacro(module: "AbuseOfNotationMacros", type: "Sqrt2ConvergenceProofMacro")

@attached(member, names: arbitrary)
public macro MultiplicationCommutativityProof(leftOperand: Int, depth: Int) = #externalMacro(module: "AbuseOfNotationMacros", type: "MultiplicationCommutativityProofMacro")

@attached(member, names: arbitrary)
public macro WallisProductProof(depth n: Int) = #externalMacro(module: "AbuseOfNotationMacros", type: "WallisProductProofMacro")
