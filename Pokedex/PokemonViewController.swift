import UIKit

class PokemonViewController: UIViewController {
    var url: String!
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var type1Label: UILabel!
    @IBOutlet var type2Label: UILabel!
    @IBOutlet var catchButton: UIButton!
    @IBOutlet var spriteImage: UIImageView!
    @IBOutlet var descLabel: UILabel!
    
    var caught = false
    var currentPokemon: Int = 0
    var caughtPokemon: [Int] = []
    var currentDescURL: String!
    
    let defaults = UserDefaults.standard

    func capitalize(text: String) -> String {
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        nameLabel.text = ""
        numberLabel.text = ""
        type1Label.text = ""
        type2Label.text = ""
        catchButton.setTitle("", for: .normal)
        descLabel.text = ""
        
        loadPokemon()
    }

    func loadPokemon() {
        URLSession.shared.dataTask(with: URL(string: url)!) { (data, response, error) in
            guard let data = data else {
                return
            }

            do {
                let result = try JSONDecoder().decode(PokemonResult.self, from: data)
                DispatchQueue.main.async {
                    self.navigationItem.title = self.capitalize(text: result.name)
                    self.nameLabel.text = self.capitalize(text: result.name)
                    self.numberLabel.text = String(format: "#%03d", result.id)
                    self.currentPokemon = result.id
                    
                    for typeEntry in result.types {
                        if typeEntry.slot == 1 {
                            self.type1Label.text = self.capitalize(text: typeEntry.type.name)
                        }
                        else if typeEntry.slot == 2 {
                            self.type2Label.text = self.capitalize(text: typeEntry.type.name)
                        }
                    }
                    
                    // MARK: Image config
                    guard let imageURL = URL(string: result.sprites.front_default) else {
                        return
                    }
                    if let d = try? Data(contentsOf: imageURL) {
                        self.spriteImage.image = UIImage(data: d)
                    }
                    
                    self.currentDescURL = result.species.url
                    self.showDesc()
                    
                    if let caughtPokes = self.defaults.array(forKey: "caughtPokemon") {
                        self.caughtPokemon = caughtPokes as! [Int]
                    }
                    self.setCaughtLabel()
                }
            }
            catch let error {
                print(error)
            }
        }.resume()
    }
    
//    MARK: Catch button config
    @IBAction func toggleCatch() {
        caught.toggle()
        if caught == true {
            catchButton.setTitle("Release", for: .normal)
            caughtPokemon.append(currentPokemon)
            defaults.set(caughtPokemon, forKey: "caughtPokemon")
        }
        else if caught == false {
            catchButton.setTitle("Catch", for: .normal)
            if let index = caughtPokemon.firstIndex(of: currentPokemon) {
                caughtPokemon.remove(at: index)
            }
            defaults.set(caughtPokemon, forKey: "caughtPokemon")
        }
    }
    
    func setCaughtLabel() {
        if caughtPokemon.contains(currentPokemon) {
            catchButton.setTitle("Release", for: .normal)
            caught = true
        }
        else {
            catchButton.setTitle("Catch", for: .normal)
            caught = false
        }
    }
    
//    MARK: Description config
    func showDesc() {
        URLSession.shared.dataTask(with: URL(string: currentDescURL)!) { (data, response, error) in
            guard let data = data else {
                return
            }
            do {
                let result = try JSONDecoder().decode(PokemonDesc.self, from: data)
                DispatchQueue.main.async {
                    for index in 0 ..< result.flavor_text_entries.count {
                        if result.flavor_text_entries[index].language.name == "en" {
                            self.descLabel.text = result.flavor_text_entries[index].flavor_text
                        }
                    }
                }
            }
            catch let error {
                print(error)
            }
        }.resume()
    }
}
