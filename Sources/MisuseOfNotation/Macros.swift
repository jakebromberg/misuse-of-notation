@attached(peer, names: arbitrary)
public macro ProductConformance(_ multiplier: Int) = #externalMacro(module: "MisuseOfNotationMacros", type: "ProductConformanceMacro")

@attached(member, names: arbitrary)
public macro FibonacciProof(upTo n: Int) = #externalMacro(module: "MisuseOfNotationMacros", type: "FibonacciProofMacro")

@attached(member, names: arbitrary)
public macro PiConvergenceProof(depth n: Int) = #externalMacro(module: "MisuseOfNotationMacros", type: "PiConvergenceProofMacro")

@attached(member, names: arbitrary)
public macro GoldenRatioProof(depth n: Int) = #externalMacro(module: "MisuseOfNotationMacros", type: "GoldenRatioProofMacro")

@attached(member, names: arbitrary)
public macro Sqrt2ConvergenceProof(depth n: Int) = #externalMacro(module: "MisuseOfNotationMacros", type: "Sqrt2ConvergenceProofMacro")

@attached(member, names: arbitrary)
public macro MultiplicationCommutativityProof(leftOperand: Int, depth: Int) = #externalMacro(module: "MisuseOfNotationMacros", type: "MultiplicationCommutativityProofMacro")

@attached(member, names: arbitrary)
public macro WallisProductProof(depth n: Int) = #externalMacro(module: "MisuseOfNotationMacros", type: "WallisProductProofMacro")

@attached(member, names: arbitrary)
public macro CFDeterminantProof(coefficients: [Int]) = #externalMacro(module: "MisuseOfNotationMacros", type: "CFDeterminantProofMacro")
