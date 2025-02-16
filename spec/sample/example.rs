fn quicksort(array: &mut [T]) {
    if array.len() <= 1 {
        return;
    }
    let pivot = partition(array);
    quicksort(&mut array[pivot + 1..]); // press O here
}
