import type { ChartSpec, ChartTransform } from "./index";

function transformOutputKeys(transforms: ChartTransform[] | undefined): Set<string> {
  const keys = new Set<string>();

  for (const t of transforms ?? []) {
    if (t.type === "movingAverage" || t.type === "cumulative") {
      keys.add(t.as);
    }
    if (t.type === "group") {
      for (const agg of t.aggregations) {
        keys.add(agg.as);
      }
    }
  }

  return keys;
}

export function validateSemantics(spec: ChartSpec): string[] {
  const errors: string[] = [];

  const dimensionKeys = new Set(spec.data.dimensions.map(d => d.key));
  const measureKeys = new Set(spec.data.measures.map(m => m.key));
  const derivedKeys = transformOutputKeys(spec.data.transforms);

  if (dimensionKeys.size !== spec.data.dimensions.length) {
    errors.push("Duplicate dimension keys found.");
  }

  if (measureKeys.size !== spec.data.measures.length) {
    errors.push("Duplicate measure keys found.");
  }

  const needsXAxis = !["pie", "donut", "kpi"].includes(spec.visual.chartType);
  if (needsXAxis) {
    if (!spec.visual.xField) {
      errors.push(`visual.xField is required for chartType '${spec.visual.chartType}'.`);
    } else if (!dimensionKeys.has(spec.visual.xField)) {
      errors.push(`visual.xField '${spec.visual.xField}' is not present in data.dimensions.`);
    }
  }

  if (spec.visual.stacked && !["bar", "area", "combo"].includes(spec.visual.chartType)) {
    errors.push("visual.stacked is only valid for 'bar', 'area', or 'combo'.");
  }

  if (spec.visual.chartType === "kpi" && spec.visual.series.length !== 1) {
    errors.push("KPI charts must define exactly one series.");
  }

  for (const series of spec.visual.series) {
    const known = measureKeys.has(series.field) || derivedKeys.has(series.field);
    if (!known) {
      errors.push(
        `Series field '${series.field}' is not present in data.measures or transform outputs.`
      );
    }
  }

  if (spec.interactions?.drilldown?.enabled) {
    if (!spec.interactions.drilldown.targetRoute) {
      errors.push("interactions.drilldown.targetRoute is required when drilldown is enabled.");
    }
    if (!spec.interactions.drilldown.paramField) {
      errors.push("interactions.drilldown.paramField is required when drilldown is enabled.");
    }
  }

  for (const measure of spec.data.measures) {
    if (measure.type === "currency") {
      const hasMeasureCurrency = Boolean(measure.currency);
      const hasFormattingCurrency = Boolean(spec.formatting?.currency?.code);
      if (!hasMeasureCurrency && !hasFormattingCurrency) {
        errors.push(
          `Measure '${measure.key}' uses currency type but no currency code is defined in measure.currency or formatting.currency.code.`
        );
      }
    }
  }

  return errors;
}
