import QtQuick

QtObject {
    property bool keyboardNavigation: false

    function useKeyboard() {
        keyboardNavigation = true
    }

    function usePointer() {
        keyboardNavigation = false
    }

    function selectable(index, count, predicate) {
        if (index < 0 || index >= count) return false
        return typeof predicate !== "function" || predicate(index)
    }

    function first(count, predicate) {
        for (let index = 0; index < count; index++) {
            if (selectable(index, count, predicate)) return index
        }
        return -1
    }

    function reset(count, predicate) {
        keyboardNavigation = true
        return first(count, predicate)
    }

    function move(index, step, count, predicate) {
        if (count <= 0) return -1
        let candidate = selectable(index, count, predicate) ? index : first(count, predicate)
        if (candidate < 0) return -1
        for (let attempts = 0; attempts < count; attempts++) {
            candidate = (candidate + step + count) % count
            if (selectable(candidate, count, predicate)) return candidate
        }
        return index
    }

    function wrap(index, step, count) {
        return move(index, step, count)
    }

    function clamp(index, count) {
        return count <= 0 ? -1 : Math.max(0, Math.min(count - 1, index))
    }

    function grid(index, horizontal, vertical, columns, count) {
        if (count <= 0) return -1
        const target = index + horizontal + vertical * Math.max(1, columns)
        return clamp(target, count)
    }
}
