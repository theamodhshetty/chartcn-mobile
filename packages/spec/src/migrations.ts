import type { ChartSpec } from "./index";
import { CURRENT_SPEC_VERSION } from "./constants";
import { compareVersions, parseSpecVersion } from "./versioning";

type Migration = {
  from: string;
  to: string;
  up: (spec: ChartSpec) => ChartSpec;
};

const migrateFrom1_0_to1_1: Migration = {
  from: "1.0.0",
  to: "1.1.0",
  up: (spec) => {
    const next: ChartSpec = {
      ...spec,
      metadata: {
        ...spec.metadata,
        tags: spec.metadata.tags ?? []
      },
      visual: {
        ...spec.visual,
        xField:
          spec.visual.xField ??
          (!(["pie", "donut", "kpi"].includes(spec.visual.chartType))
            ? spec.data.dimensions[0]?.key
            : spec.visual.xField),
        tooltip: {
          enabled: spec.visual.tooltip?.enabled ?? true,
          mode: spec.visual.tooltip?.mode
        }
      },
      accessibility: {
        ...spec.accessibility,
        announceOnLoad: spec.accessibility.announceOnLoad ?? true
      },
      specVersion: "1.1.0"
    };

    return next;
  }
};

const MIGRATIONS: Migration[] = [migrateFrom1_0_to1_1];

function findNextMigration(version: string): Migration | undefined {
  const parsed = parseSpecVersion(version);

  if (parsed.major !== 1) return undefined;

  if (parsed.minor === 0) {
    return migrateFrom1_0_to1_1;
  }

  return undefined;
}

export function migrateSpec(spec: ChartSpec, targetVersion: string = CURRENT_SPEC_VERSION): ChartSpec {
  let current = spec;

  if (compareVersions(current.specVersion, targetVersion) > 0) {
    throw new Error(
      `Cannot migrate down from ${current.specVersion} to older target ${targetVersion}.`
    );
  }

  while (compareVersions(current.specVersion, targetVersion) < 0) {
    const migration = findNextMigration(current.specVersion);
    if (!migration) {
      throw new Error(`No migration path found from ${current.specVersion} to ${targetVersion}.`);
    }

    current = migration.up(current);
  }

  return current;
}

export function listMigrations(): Array<{ from: string; to: string }> {
  return MIGRATIONS.map(m => ({ from: m.from, to: m.to }));
}
