#!/usr/bin/env python3
"""Generate lib/core/icons/inventory_icon_dictionary.dart from structured data."""

from __future__ import annotations

from pathlib import Path

# (icon_key, preferred_types|None, priority_boost, terms...)
# preferred_types: 'L'=location, 'C'=container, 'I'=item, None=any
# Multi-word terms get automatic priority from word count.

RAW: list[tuple] = [
    # Habitation
    ("home", "L", 2, "maison", "house", "bungalow", "pavillon", "domicile", "residence", "résidence", "home"),
    ("apartment", "L", 2, "appartement", "appart", "condo", "condominium", "apartment", "flat", "loft"),
    ("cottage", "L", 2, "chalet", "cottage", "maison de campagne"),
    ("cabin", "L", 1, "cabane", "cabin", "hutte", "refuge"),
    ("holiday_village", "L", 1, "cottage locatif", "maison saisonniere", "maison saisonnière"),
    ("domain", "L", 1, "immeuble", "batiment", "bâtiment", "édifice", "edifice", "building", "tour"),
    ("business", "L", 1, "bureau", "office", "open space", "openspace", "coworking"),
    ("storefront", "L", 1, "magasin", "boutique", "commerce", "shop", "store", "kiosque"),
    ("warehouse", "L", 2, "entrepot", "entrepôt", "warehouse", "depot", "dépôt logistique"),
    ("garage", "L", 2, "garage", "stationnement", "parking", "stationnement interieur", "stationnement intérieur"),
    ("bedroom", "L", 2, "chambre", "chambre a coucher", "chambre à coucher", "bedroom", "master bedroom"),
    ("bed", "I", 1, "lit", "matelas", "sommier", "bed", "bunk bed", "lit superpose", "lit superposé"),
    ("kitchen", "L", 2, "cuisine", "kitchen", "coin cuisine"),
    ("bathroom", "L", 2, "salle de bain", "salle de bains", "salle d eau", "salle d'eau", "bathroom", "washroom"),
    ("bathtub", "I", 1, "baignoire", "bathtub", "jacuzzi"),
    ("living", "L", 2, "salon", "living", "salle de sejour", "salle de séjour", "living room", "family room"),
    ("meeting_room", "L", 1, "salle a manger", "salle à manger", "dining room", "salle de reunion", "salle de réunion"),
    ("door", None, 0, "porte", "portail", "door", "gate"),
    ("yard", "L", 2, "jardin", "cour", "yard", "backyard", "terrain"),
    ("fence", None, 0, "cloture", "clôture", "fence", "haie"),
    ("deck", "L", 1, "terrasse", "patio", "deck", "balcon", "veranda", "véranda"),
    ("balcony", "L", 1, "balcon", "balcony", "mezzanine"),
    ("stairs", "L", 1, "escalier", "stairs", "escalier exterieur", "escalier extérieur"),
    ("elevator", "L", 1, "ascenseur", "elevator", "monte charge", "monte-charge"),
    ("roofing", None, 0, "toit", "toiture", "grenier", "attic", "combles"),
    ("garage", "L", 1, "remise", "shed", "abri"),
    # Rangement
    ("inventory_2", "C", 1, "armoire", "commode", "buffet", "dresser", "cabinet", "placard", "garde robe", "garde-robe", "penderie"),
    ("shelves", "C", 1, "etagere", "étagère", "etagères", "étagères", "rayonnage", "shelf", "shelves", "bibliotheque meuble", "bibliothèque meuble"),
    ("drawer", "C", 1, "tiroir", "drawers", "coffre a tiroirs"),
    ("archive", "C", 1, "classeur", "archiver", "classeurs", "filing cabinet"),
    ("box", "C", 1, "boite", "boîte", "carton", "box", "caisse", "bac", "conteneur", "bin"),
    ("luggage", "C", 2, "valise", "suitcase", "luggage", "bagage", "malle"),
    ("backpack", "C", 1, "sac a dos", "sac à dos", "backpack", "sacoche", "besace"),
    ("shopping_bag", "C", 1, "sac", "sac de courses", "sac cabas", "bag", "tote"),
    ("work", "C", 1, "mallette", "briefcase", "porte documents", "porte-documents"),
    ("folder", "C", 0, "chemise", "dossier", "folder", "pochette"),
    ("safe", "C", 1, "coffre fort", "coffre-fort", "safe", "coffre"),
    ("inventory_2", "C", 0, "contenant", "rangement", "storage", "organiseur"),
    # Mobilier / déco
    ("chair", "I", 1, "chaise", "chair", "fauteuil", "tabouret", "stool", "banc"),
    ("chair_alt", "I", 1, "chaise de bureau", "siege de bureau", "siège de bureau", "office chair"),
    ("table_restaurant", "I", 1, "table", "table a manger", "table à manger", "dining table"),
    ("table_bar", "I", 0, "ilot", "îlot", "comptoir", "bar", "table haute"),
    ("desk", "I", 2, "bureau meuble", "desk", "secretaire", "secrétaire", "poste de travail"),
    ("weekend", "I", 1, "canape", "canapé", "sofa", "divan", "causeuse", "loveseat"),
    ("lamp", "I", 1, "lampe", "lamp", "luminaire", "abat jour", "abat-jour", "veilleuse"),
    ("light", "I", 0, "eclairage", "éclairage", "plafonnier", "applique", "guirlande"),
    ("blinds", "I", 1, "store", "stores", "blinds", "persienne"),
    ("curtain", "I", 1, "rideau", "rideaux", "curtain", "voilage"),
    ("palette", "I", 0, "decoration", "décoration", "deco", "déco", "cadre", "poster", "tableau"),
    ("image", "I", 0, "photo cadre", "affiche", "mirroir", "miroir", "mirror"),
    ("checkroom", "I", 0, "portemanteau", "porte manteau", "porte-manteau", "patere", "patère"),
    # Informatique
    ("laptop", "I", 3, "ordinateur portable", "portable", "laptop", "notebook", "macbook", "chromebook"),
    ("desktop", "I", 2, "ordinateur de bureau", "pc de bureau", "desktop", "tour"),
    ("computer", "I", 1, "ordinateur", "computer", "pc", "imac"),
    ("monitor", "I", 2, "ecran", "écran", "moniteur", "monitor", "display"),
    ("tv", "I", 2, "television", "télévision", "tele", "télé", "tv", "smart tv", "televiseur", "téléviseur"),
    ("keyboard", "I", 2, "clavier", "keyboard"),
    ("headphones", "I", 2, "ecouteurs", "écouteurs", "casque audio", "headphones", "earbuds", "airpods"),
    ("headset", "I", 1, "casque micro", "headset", "micro casque"),
    ("speaker", "I", 1, "haut parleur", "haut-parleur", "enceinte", "speaker", "barre de son", "soundbar"),
    ("smartphone", "I", 2, "telephone", "téléphone", "cellphone", "cellulaire", "smartphone", "iphone", "android"),
    ("tablet", "I", 2, "tablette", "tablet", "ipad"),
    ("watch", "I", 1, "montre", "watch", "montre intelligente", "smartwatch", "apple watch"),
    ("print", "I", 2, "imprimante", "printer", "print"),
    ("scanner", "I", 1, "scanner", "numeriseur", "numériseur"),
    ("router", "I", 2, "routeur", "router", "modem", "point d acces", "point d'accès", "access point"),
    ("wifi", "I", 1, "wifi", "wi-fi", "reseau", "réseau", "ethernet"),
    ("cable", "I", 1, "cable", "câble", "cable reseau", "câble réseau", "cable hdmi", "câble hdmi", "cable usb", "câble usb"),
    ("usb", "I", 1, "usb", "cle usb", "clé usb", "usb stick", "dongle"),
    ("memory", "I", 1, "ram", "memoire", "mémoire", "processeur", "cpu", "carte mere", "carte mère", "motherboard"),
    ("sd_card", "I", 1, "carte sd", "sd card", "microsd", "carte memoire", "carte mémoire"),
    ("hard_drive", "I", 2, "disque dur", "disque ssd", "ssd", "hdd", "stockage", "hard drive", "nas"),
    ("gamepad", "I", 1, "manette", "console", "gamepad", "joystick", "playstation", "xbox", "nintendo", "switch"),
    ("camera", "I", 2, "appareil photo", "camera", "caméra", "reflex", "hybride"),
    ("videocam", "I", 1, "camera video", "caméra vidéo", "camcorder", "webcam"),
    ("battery", "I", 1, "batterie", "pile", "battery", "chargeur", "powerbank", "batterie externe"),
    ("power", "I", 0, "alimentation", "adaptateur", "bloc d alimentation", "bloc d'alimentation", "psu"),
    ("bolt", "I", 0, "prise", "multiprise", "rallonge", "extension cord"),
    # Électroménager / cuisine
    ("kitchen", "I", 0, "frigo", "refrigerateur", "réfrigérateur", "fridge", "congelateur", "congélateur", "freezer"),
    ("microwave", "I", 2, "micro ondes", "micro-ondes", "microwave"),
    ("oven", "I", 2, "four", "oven", "cuisiniere", "cuisinière", "plaque de cuisson"),
    ("dishwasher", "I", 2, "lave vaisselle", "lave-vaisselle", "dishwasher"),
    ("wash", "I", 2, "lave linge", "lave-linge", "machine a laver", "machine à laver", "washer", "seche linge", "sèche-linge", "dryer"),
    ("coffee", "I", 2, "cafetiere", "cafetière", "machine a cafe", "machine à café", "espresso", "nespresso", "percolateur"),
    ("blender", "I", 1, "melangeur", "mélangeur", "blender", "mixeur", "robot culinaire", "batteur"),
    ("restaurant", "I", 1, "grille pain", "grille-pain", "toaster"),
    ("vacuum", "I", 2, "aspirateur", "vacuum", "balai electrique", "balai électrique"),
    ("iron", "I", 1, "fer a repasser", "fer à repasser", "iron", "table a repasser", "table à repasser"),
    ("ac_unit", "I", 1, "climatiseur", "air climatise", "air climatisé", "ac", "thermopompe", "heat pump"),
    ("thermostat", "I", 1, "thermostat", "chauffage", "radiateur", "heater"),
    ("flatware", "I", 1, "couverts", "fourchette", "couteau", "cuillere", "cuillère", "flatware", "ustensile", "ustensiles"),
    ("dining", "I", 1, "assiette", "bol", "plat", "vaisselle", "dishes", "casserole", "poele", "poêle", "faitout"),
    ("restaurant", "I", 0, "cuisine equipement", "batterie de cuisine"),
    ("local_pizza", "I", 0, "pizza", "snack"),
    ("bakery", "I", 1, "pain", "baguette", "croissant", "patisserie", "pâtisserie", "bakery"),
    ("liquor", "I", 1, "alcool", "biere", "bière", "beer", "spiritueux", "whisky", "vodka"),
    ("wine", "I", 1, "vin", "wine", "champagne", "bouteille de vin"),
    ("water", "I", 0, "eau", "water", "boisson", "jus", "soda", "boissons"),
    ("local_pizza", "I", 0, "nourriture", "aliment", "aliments", "epicerie", "épicerie", "food", "grocery", "provision", "provisions", "reserve", "réserve"),
    # Vêtements / bijoux
    ("apparel", "I", 1, "vetement", "vêtement", "vetements", "vêtements", "habit", "habits", "clothing", "clothes", "chandail", "tshirt", "t-shirt", "chemise", "pantalon", "jeans", "jupe", "robe", "manteau", "manteaux", "veste", "hoodie", "sweater"),
    ("dry_cleaning", "I", 0, "costume", "cravate", "ceinture"),
    ("shoes", "I", 1, "chaussure", "chaussures", "soulier", "souliers", "botte", "bottes", "sandale", "sandals", "espadrille", "shoes", "sneakers", "running"),
    ("diamond", "I", 1, "bijou", "bijoux", "bague", "collier", "bracelet", "boucle d oreille", "boucle d'oreille", "jewelry", "montre bijou"),
    ("soap", "I", 1, "savon", "shampooing", "shampoing", "dentifrice", "deodorant", "déodorant", "hygiene", "hygiène", "soap"),
    ("spa", "I", 1, "creme", "crème", "maquillage", "cosmetique", "cosmétique", "parfum", "beaute", "beauté", "beauty"),
    ("medication", "I", 2, "medicament", "médicament", "medicaments", "médicaments", "vitamine", "vitamines", "pillule", "comprimes", "comprimés", "pharmacy", "pharmacie"),
    ("medical", "I", 1, "trousse de premiers soins", "first aid", "bandage", "pansement", "thermometre", "thermomètre"),
    ("health", "I", 0, "sante", "santé", "health"),
    ("content_cut", "I", 0, "ciseaux", "scissors", "coupe ongles", "coupe-ongles"),
    # Entretien / outils
    ("cleaning", "I", 1, "nettoyage", "detergent", "détergent", "javellisant", "bleach", "desinfectant", "désinfectant", "produit menager", "produit ménager", "cleaning"),
    ("broom", "I", 1, "balai", "serpilliere", "serpillière", "mop", "dustpan", "pelle a poussiere", "pelle à poussière"),
    ("handyman", None, 3, "outil", "outils", "tool", "tools", "boite a outils", "boîte à outils", "toolbox", "boite a outil", "boîte à outil"),
    ("build", "I", 1, "marteau", "tournevis", "cle", "clé", "clef", "pince", "hammer", "screwdriver", "wrench"),
    ("hardware", "I", 1, "vis", "clou", "ecrou", "écrou", "boulon", "quincaillerie", "hardware"),
    ("construction", "I", 1, "perceuse", "scie", "drill", "saw", "ponceuse", "visseusse", "visseuse"),
    ("plumbing", "I", 1, "plomberie", "tuyau", "robinet", "plumbing", "pipe"),
    ("electrical", "I", 1, "electricite", "électricité", "fil electrique", "fil électrique", "disjoncteur"),
    ("carpentry", "I", 1, "bois", "planche", "madrier", "lumber", "plywood", "contreplaque", "contreplaqué"),
    ("paint", "I", 1, "peinture", "paint", "pinceau", "rouleau", "vernis"),
    ("straighten", "I", 0, "metre", "mètre", "ruban a mesurer", "ruban à mesurer", "niveau", "level"),
    ("mouse", "I", 2, "souris", "mouse", "trackpad", "souris sans fil", "souris optique"),
    # Transport
    ("directions_car", "I", 2, "voiture", "auto", "automobile", "car", "vehicle", "vehicule", "véhicule", "camionnette", "suv"),
    ("local_shipping", "I", 1, "camion", "truck", "van", "fourgon"),
    ("two_wheeler", "I", 2, "moto", "motorcycle", "scooter", "motocyclette"),
    ("pedal_bike", "I", 2, "velo", "vélo", "bicycle", "bike", "bicyclette", "velo electrique", "vélo électrique", "ebike"),
    ("electric_scooter", "I", 1, "trottinette", "trottinette electrique", "trottinette électrique"),
    ("directions_boat", "I", 1, "bateau", "boat", "kayak", "canoe", "canot", "chaloupe"),
    ("flight", "I", 0, "avion", "flight", "billet d avion"),
    ("tire", "I", 1, "pneu", "pneus", "tire", "roue", "jante"),
    ("local_gas", "I", 1, "essence", "carburant", "gas", "diesel"),
    ("ev_station", "I", 1, "borne de recharge", "chargeur vehicule", "chargeur véhicule"),
    ("key", "I", 1, "cle de voiture", "clé de voiture", "clefs", "clés", "porte cle", "porte-clés", "keychain"),
    # Jardin
    ("grass", "I", 1, "gazon", "tondeuse", "lawn", "mower", "coupe bordure", "coupe-bordure"),
    ("potted_plant", "I", 2, "plante", "plantes", "planteau", "fleur", "fleurs", "pot de fleur", "plant", "flower"),
    ("agriculture", "I", 1, "terreau", "engrais", "semence", "graines", "jardinage", "gardening", "pelle de jardin", "rateau", "râteau", "arrosoir"),
    ("forest", "L", 0, "foret", "forêt", "bois exterieur", "bois extérieur"),
    ("compost", "I", 1, "compost", "composteur", "recyclage", "bac de recyclage"),
    ("camping", "I", 1, "tente", "camping", "sac de couchage", "sleeping bag", "rechaud", "réchaud"),
    ("hiking", "I", 1, "randonnee", "randonnée", "hiking", "baton de marche", "bâton de marche"),
    # Sports
    ("fitness", "I", 2, "halteres", "haltères", "dumbbell", "musculation", "gym", "fitness", "tapis de course", "velo stationnaire", "vélo stationnaire"),
    ("sports_soccer", "I", 1, "ballon", "soccer", "football", "soccer ball"),
    ("sports_tennis", "I", 1, "tennis", "raquette", "badminton"),
    ("sports_basketball", "I", 1, "basketball", "basket"),
    ("sports_hockey", "I", 1, "hockey", "patin", "patins", "stick de hockey"),
    ("pool", "I", 1, "piscine", "pool", "maillot de bain", "lunettes de natation"),
    ("skateboarding", "I", 1, "planche a neige", "planche à neige", "snowboard", "ski", "skis", "skateboard"),
    ("self_improvement", "I", 0, "yoga", "meditation", "méditation"),
    # Musique / média
    ("music_note", "I", 1, "musique", "partition", "music"),
    ("piano", "I", 2, "piano", "clavier musical", "orgue", "synthe", "synthétiseur", "synthetiseur"),
    ("music_note", "I", 2, "guitare", "guitar", "basse", "ukulele", "ukulélé", "violon", "violin", "batterie", "drums"),
    ("radio", "I", 1, "radio", "autoradio"),
    ("album", "I", 0, "cd", "vinyle", "disque", "vinyl"),
    ("movie", "I", 1, "film", "dvd", "bluray", "blu-ray", "movie"),
    # Livres / docs
    ("menu_book", "I", 2, "livre", "livres", "book", "books", "roman", "manuel", "bande dessinee", "bande dessinée", "bd", "manga"),
    ("auto_stories", "I", 1, "magazine", "revue", "catalogue", "journal"),
    ("description", "I", 1, "document", "documents", "contrat", "facture", "facture papier", "papier", "formulaire"),
    ("article", "I", 0, "rapport", "memoire", "mémoire", "these", "thèse"),
    ("sticky_note", "I", 0, "post it", "post-it", "note", "aide memoire", "aide-mémoire"),
    ("edit", "I", 1, "stylo", "pen", "crayon", "pencil", "marqueur", "surligneur"),
    ("draw", "I", 1, "cahier", "carnet", "notebook", "bloc notes", "bloc-notes", "agenda"),
    ("calculator", "I", 1, "calculatrice", "calculator"),
    ("mail", "I", 0, "enveloppe", "courrier", "lettre", "timbre"),
    # Jeux / enfants / animaux
    ("toys", "I", 1, "jouet", "jouets", "toy", "toys", "peluche", "poupée", "poupee", "lego"),
    ("extension", "I", 1, "puzzle", "jeu de societe", "jeu de société", "board game", "cartes"),
    ("casino", "I", 0, "dés", "des", "jetons"),
    ("child_care", "I", 1, "bebe", "bébé", "baby", "poussette", "biberon", "couche", "couches"),
    ("pets", "I", 2, "chien", "chat", "animal", "animaux", "pet", "pets", "croquette", "croquettes", "laisse", "cage", "aquarium", "litiere", "litière"),
    ("cruelty_free", "I", 0, "oiseau", "hamster", "lapin"),
    # Pro / conso
    ("badge", "I", 0, "carte", "badge", "identite", "identité", "permis"),
    ("science", "I", 0, "laboratoire", "lab", "echantillon", "échantillon"),
    ("factory", "L", 1, "usine", "atelier", "factory", "workshop"),
    ("precision", "I", 0, "equipement professionnel", "équipement professionnel", "machine industrielle"),
    ("shopping_cart", "I", 0, "achat", "a acheter", "à acheter", "liste d epicerie", "liste d'épicerie"),
    ("redeem", "I", 0, "cadeau", "gift", "coffret"),
    ("savings", "I", 0, "argent", "encaisse", "caisse"),
    ("receipt", "I", 0, "recu", "reçu", "ticket"),
    ("qr_code", "I", 0, "code barres", "code-barres", "barcode", "qr code"),
    ("sell", "I", 0, "a vendre", "à vendre", "revente"),
    ("category", None, 0, "divers", "autre", "misc", "miscellaneous", "objet", "article"),
]

OUT = Path(__file__).resolve().parents[1] / "lib" / "core" / "icons" / "inventory_icon_dictionary.dart"


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def main() -> None:
    lines: list[str] = []
    lines.append("// GENERATED by tool/gen_icon_dictionary.py — do not edit by hand.")
    lines.append("// ignore_for_file: lines_longer_than_80_chars")
    lines.append("")
    lines.append("import '../domain/inventory_models.dart';")
    lines.append("import 'inventory_icon_entry.dart';")
    lines.append("")
    lines.append("/// Static local dictionary (FR-QC + synonymes, quelques termes EN).")
    lines.append("abstract final class InventoryIconDictionary {")
    lines.append("  static const List<InventoryIconEntry> entries = [")

    seen_terms: set[str] = set()
    count = 0
    for row in RAW:
        if not row or row[0] is False:
            continue
        icon, pref, boost, *terms = row
        pref_code = {
            None: "null",
            "L": "NodeType.location",
            "C": "NodeType.itemContainer",
            "I": "NodeType.item",
        }[pref]
        for term in terms:
            key = term.strip().lower()
            if not key or key in seen_terms:
                continue
            seen_terms.add(key)
            words = len(key.split())
            priority = boost + words * 10
            lines.append(
                "    InventoryIconEntry("
                f"iconKey: '{icon}', "
                f"term: '{esc(term)}', "
                f"priority: {priority}, "
                f"preferredType: {pref_code}"
                "),"
            )
            count += 1

    lines.append("  ];")
    lines.append("")
    lines.append(f"  static const int termCount = {count};")
    lines.append(f"  static const int familyCount = {len({r[0] for r in RAW if r and r[0] is not False})};")
    lines.append("}")
    lines.append("")

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {count} terms -> {OUT}")


if __name__ == "__main__":
    main()
