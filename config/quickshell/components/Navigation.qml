import QtQuick

QtObject {
    function wrap(index, step, count) {
        if (count <= 0) return 0
        return (index + step + count) % count
    }

    function clamp(index, count) {
        return count <= 0 ? 0 : Math.max(0, Math.min(count - 1, index))
    }

    function grid(index, horizontal, vertical, columns, count) {
        if (count <= 0) return 0
        const target = index + horizontal + vertical * Math.max(1, columns)
        return clamp(target, count)
    }
}
