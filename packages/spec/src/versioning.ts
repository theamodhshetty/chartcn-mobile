import { SUPPORTED_SPEC_MAJOR } from "./constants";

export interface ParsedVersion {
  raw: string;
  major: number;
  minor: number;
  patch: number;
}

export function parseSpecVersion(input: string): ParsedVersion {
  const match = /^([0-9]+)\.([0-9]+)\.([0-9]+)$/.exec(input);
  if (!match) {
    throw new Error(`Invalid specVersion '${input}'. Expected semver like 1.1.0`);
  }

  const major = Number(match[1]);
  const minor = Number(match[2]);
  const patch = Number(match[3]);

  if ([major, minor, patch].some(n => Number.isNaN(n))) {
    throw new Error(`Invalid specVersion '${input}'.`);
  }

  return { raw: input, major, minor, patch };
}

export function compareVersions(a: string, b: string): number {
  const left = parseSpecVersion(a);
  const right = parseSpecVersion(b);

  if (left.major !== right.major) return left.major - right.major;
  if (left.minor !== right.minor) return left.minor - right.minor;
  return left.patch - right.patch;
}

export function isRuntimeCompatible(specVersion: string): boolean {
  const parsed = parseSpecVersion(specVersion);
  return parsed.major === SUPPORTED_SPEC_MAJOR;
}

export function assertRuntimeCompatible(specVersion: string): void {
  if (!isRuntimeCompatible(specVersion)) {
    throw new Error(
      `Unsupported spec major for '${specVersion}'. Supported major: ${SUPPORTED_SPEC_MAJOR}`
    );
  }
}
