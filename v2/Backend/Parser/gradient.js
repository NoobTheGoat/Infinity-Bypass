const gradient = require('gradient-string');

const colorMap = {
  red: {
    color1: "#E21F1F",
    color2: "#DA7E7E"
  },
  blue: {
    color1: "#7A71C4",
    color2: "#1830E7"
  },
  green: {
    color1: "#9FF76F",
    color2: "#1FA132"
  },
  purple: {
    color1: "#6D51A5",
    color2: "#B3A6E3"
  },
  cyan: {
    color1: "#6FE3E1",
    color2: "#5257E5"
  },
  black: {
    color1: "#0E1C26",
    color2: "#294861"
  },
  orange: {
    color1: "#F74C06",
    color2: "#F9BC2C"
  },
  yellow: {
    color1: "#BDA734",
    color2: "#F7F2AB"
  },
  white: {
    color1: "#EBF4F5",
    color2: "#B5C6E0"
  },
  pink: {
    color1: "#FF5858",
    color2: "#FFC8C8",
  },
  darkgreen: {
    color1: "#4A9B7F",
    color2: "#0A3431"
  },
  lime: {
    color1: "#82F4B1",
    color2: "#30C67C"
  }
}

async function log(message, colorName) {
  const colorSelection = colorMap[colorName] || colorMap.white
  const color1 = colorSelection.color1;
  const color2 = colorSelection.color2;
  console.log(gradient(color1, color2)(message));
}

module.exports = { log }