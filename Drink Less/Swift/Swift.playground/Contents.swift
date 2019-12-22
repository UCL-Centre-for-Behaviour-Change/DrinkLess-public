import Foundation


/////////////////////////////////////////
// THE WEIGHTED RANDOM PICKER FUNCTION
/////////////////////////////////////////

func chooseRandom(weights:[String:Int]) -> String {
    // Get the total bucket size
    var total = 0
    weights.values.forEach { (ele) in
        total = total + ele
    }
    
    let random = Int.random(in: 1...total)
    var accum = 0
    var chosen : String?
    for key in weights.keys.sorted() {
        let value = weights[key]!
        accum = accum + value
        if accum >= random {
            //Log.d("MRT - [rand] T=\(total) r=\(random) key=\(key) val=\(value) accum=\(accum)")
            chosen = key
            break
        }
    }
    
    return chosen!
}

/////////////////////////////////////////
// THE WEIGHTS
/////////////////////////////////////////

let VERSION_PROBS = ["A": 1, "B": 1, "C": 3]   // 20% / 20% / 60%
let VERSION_C_PROBS = ["c1": 4, "c2": 3, "c3": 3]    // 40% / 30% / 30%

/////////////////////////////////////////
// TEST & PROOF
/////////////////////////////////////////
if true {
var trialResults = ["A":0, "B":0, "C":0]
for _ in 1...5000 {
    let trial = chooseRandom(weights: VERSION_PROBS)
    trialResults[trial]! = trialResults[trial]! + 1
}
let max = Float(trialResults.values.reduce(0,{x, y in x+y}))
let perc = ["A": Float(trialResults["A"]!) / max * 100,
            "B": Float(trialResults["B"]!) / max * 100,
            "C": Float(trialResults["C"]!) / max * 100]
print(String(format:"Trial Results: A: %i, B: %i, C: %i ", trialResults["A"]!, trialResults["B"]!, trialResults["C"]!))

print(String(format:"Normalised: %.0f%% / %.0f%% / %.0f%%", roundf(perc["A"]!), roundf(perc["B"]!), roundf(perc["C"]!)))
}

/////////////////////////////////////////
// TEST & PROOF VERSION C
/////////////////////////////////////////
if true {
var trialResults = ["c1":0, "c2":0, "c3":0]
for _ in 1...5000 {
    let trial = chooseRandom(weights: VERSION_C_PROBS)
    trialResults[trial] = trialResults[trial]! + 1
}
let max = Float(trialResults.values.reduce(0,{x, y in x+y}))
let perc = ["c1": Float(trialResults["c1"]!) / max * 100,
            "c2": Float(trialResults["c2"]!) / max * 100,
            "c3": Float(trialResults["c3"]!) / max * 100]
print(String(format:"Trial C Results: c1: %i, c2: %i, c3: %i", trialResults["c1"]!, trialResults["c2"]!, trialResults["c3"]!))

print(String(format:"Normalised: %.0f%% / %.0f%% / %.0f%% ", roundf(perc["c1"]!), roundf(perc["c2"]!), roundf(perc["c3"]!)))
}




