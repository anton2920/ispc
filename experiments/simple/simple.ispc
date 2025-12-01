export
void
simple(uniform float vout[], uniform float vin[], uniform int count)
{
	foreach (index = 0 ... count) {
		float v = vin[index];
		if (v < 3.) {
			v = v * v;
		} else {
			v = sqrt(v);
		}
		vout[index] = v;
	}
}
