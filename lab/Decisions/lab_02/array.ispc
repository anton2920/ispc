template <typename T>
uniform T
ArrayMin(uniform T array[], uniform int len)
{
	T min = array[0];
	foreach (i = 1...len) {
		if (array[i] < min) {
			min = array[i];
		}
	}
	return reduce_min(min);
}


template <typename T>
uniform T
ArrayMax(uniform T array[], uniform int len)
{
	T max = array[0];
	foreach (i = 0...len) {
		if (array[i] > max) {
			max = array[i];
		}
	}
	return reduce_max(max);
}


template <typename T>
void
ArrayPrint(uniform T array[], uniform int len)
{
	print("[");
	for (uniform int i = 0; i < len; i++) {
		if (i > 0) {
			print(", ");
		}
		print("%", array[i]);
	}
	print("]");
}


template <typename T>
void
ArrayPrintln(uniform T array[], uniform int len)
{
	ArrayPrint(array, len);
	print("\n");
}


template <typename T>
uniform float
ArrayRMS(uniform T array[], uniform int len)
{
	T sum = 0;
	foreach (i = 0...len) {
		sum += array[i]*array[i];
	}
	return sqrt((uniform float)reduce_add(sum) / len);
}


