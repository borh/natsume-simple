export type Result = {
	n?: string;
	v: string;
	frequency: number;
	corpus: string;
	p: string;
	contributions?: { corpus: string; frequency: number }[];
};

export type CombinedResult = {
	v: string;
	frequency: number;
	contributions: { corpus: string; frequency: number }[];
	p: string;
};
