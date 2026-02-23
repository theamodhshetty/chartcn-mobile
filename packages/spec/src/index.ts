export type SpecStatus = "experimental" | "beta" | "stable" | "deprecated";
export type ChartType = "line" | "bar" | "area" | "pie" | "donut" | "scatter" | "combo" | "kpi";
export type AdapterType = "swiftdata" | "room" | "sqldelight" | "api" | "static";

export interface ChartSpec {
  specVersion: `1.${number}.${number}`;
  id: string;
  metadata: ChartMetadata;
  data: ChartData;
  visual: ChartVisual;
  formatting?: ChartFormatting;
  interactions?: ChartInteractions;
  theming?: ChartTheming;
  accessibility: ChartAccessibility;
  platformOverrides?: PlatformOverrides;
}

export interface ChartMetadata {
  name: string;
  description?: string;
  tags?: string[];
  status: SpecStatus;
  owners: string[];
  updatedAt?: string;
}

export interface ChartData {
  source: SwiftDataSource | RoomSource | SqlDelightSource | ApiSource | StaticSource;
  dimensions: ChartDimension[];
  measures: ChartMeasure[];
  filters?: ChartFilter[];
  transforms?: ChartTransform[];
}

export interface ChartDimension {
  key: string;
  type: "time" | "string" | "number" | "boolean";
  label: string;
}

export interface ChartMeasure {
  key: string;
  type: "number" | "duration" | "percent" | "currency";
  label: string;
  unit?: string;
  currency?: string;
}

export interface OrderBy {
  field: string;
  direction: "asc" | "desc";
}

export interface SwiftDataSource {
  adapter: "swiftdata";
  entity: string;
  predicate?: string;
  sort?: OrderBy[];
  limit?: number;
}

export interface RoomSource {
  adapter: "room";
  table: string;
  where?: string;
  args?: Array<string | number | boolean | null>;
  orderBy?: OrderBy[];
  limit?: number;
}

export interface SqlDelightSource {
  adapter: "sqldelight";
  queryName: string;
  args?: Record<string, string | number | boolean | null>;
}

export interface ApiSource {
  adapter: "api";
  endpoint: string;
  method: "GET" | "POST";
  headers?: Record<string, string>;
  query?: Record<string, string | number | boolean | null>;
  body?: Record<string, unknown>;
  dataPath?: string;
}

export interface StaticSource {
  adapter: "static";
  rows: Array<Record<string, string | number | boolean | null>>;
}

export interface ChartFilter {
  field: string;
  op: "eq" | "neq" | "gt" | "gte" | "lt" | "lte" | "in" | "between" | "contains";
  value: string | number | boolean | null | Array<string | number | boolean | null>;
}

export type ChartTransform = SortTransform | MovingAverageTransform | CumulativeTransform | GroupTransform;

export interface SortTransform {
  type: "sort";
  by: string;
  direction: "asc" | "desc";
}

export interface MovingAverageTransform {
  type: "movingAverage";
  input: string;
  window: number;
  as: string;
}

export interface CumulativeTransform {
  type: "cumulative";
  input: string;
  as: string;
}

export interface GroupTransform {
  type: "group";
  by: string[];
  aggregations: Array<{
    field: string;
    op: "sum" | "avg" | "min" | "max" | "count";
    as: string;
  }>;
}

export interface ChartVisual {
  chartType: ChartType;
  xField?: string;
  groupField?: string;
  stacked?: boolean;
  series: ChartSeries[];
  legend?: {
    visible?: boolean;
    position?: "top" | "bottom" | "left" | "right";
  };
  axes?: {
    x?: ChartAxis;
    y?: ChartAxis;
  };
  tooltip?: {
    enabled?: boolean;
    mode?: "nearest" | "index";
  };
  emptyState?: {
    title?: string;
    description?: string;
  };
}

export interface ChartSeries {
  field: string;
  label: string;
  renderer?: "line" | "bar" | "area" | "scatter" | "kpi";
  style?: {
    color?: string;
    lineWidth?: number;
    dash?: number[];
    opacity?: number;
  };
}

export interface ChartAxis {
  label?: string;
  min?: number;
  max?: number;
  tickCount?: number;
}

export interface ChartFormatting {
  number?: {
    notation?: "standard" | "compact";
    maximumFractionDigits?: number;
  };
  currency?: {
    code?: string;
    display?: "symbol" | "code" | "name";
  };
  date?: {
    granularity?: "hour" | "day" | "week" | "month" | "quarter" | "year";
  };
}

export interface ChartInteractions {
  selection?: "none" | "single" | "multiple";
  drilldown?: {
    enabled?: boolean;
    targetRoute?: string;
    paramField?: string;
  };
  gestures?: Array<"pan" | "pinch" | "tap" | "longPress">;
}

export interface ChartTheming {
  palette?: string;
  tokens?: Record<string, string>;
}

export interface ChartAccessibility {
  chartTitle: string;
  summaryTemplate: string;
  announceOnLoad?: boolean;
}

export interface PlatformOverrides {
  ios?: {
    interpolation?: "linear" | "monotone" | "catmullRom";
    symbolSize?: number;
  };
  android?: {
    curveStyle?: "straight" | "smooth";
    pointRadius?: number;
  };
}
