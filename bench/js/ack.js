function ack(m, n) {
    if (m == 0) {
        return n + 1;
    } else {
        if (n == 0) {
            return ack(m - 1, 1);
        } else {
            return ack(m - 1, rec(m, n - 1));
        }
    }
}

console.log(ack(3, 12))
