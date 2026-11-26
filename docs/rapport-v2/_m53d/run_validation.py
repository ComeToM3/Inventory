import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path

ADB = ["adb", "-s", "ZT322P23HJ"]
OUT = Path("docs/rapport-v2/_m53d")
OUT.mkdir(parents=True, exist_ok=True)
log: list[str] = []


def sh(*a: str) -> None:
    subprocess.check_call(ADB + list(a))


def dump(name: str) -> str:
    sh("shell", "uiautomator", "dump", "/sdcard/m53d.xml")
    sh("pull", "/sdcard/m53d.xml", str(OUT / f"{name}.xml"))
    return (OUT / f"{name}.xml").read_text(encoding="utf-8")


def parse(xml: str) -> list[dict]:
    root = ET.fromstring(xml)
    res = []
    for n in root.iter("node"):
        b = n.attrib.get("bounds", "")
        m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", b)
        if not m:
            continue
        x1, y1, x2, y2 = map(int, m.groups())
        res.append(
            {
                "text": n.attrib.get("text", ""),
                "desc": n.attrib.get("content-desc", "").replace("&#10;", "\n"),
                "cls": n.attrib.get("class", ""),
                "click": n.attrib.get("clickable") == "true",
                "cx": (x1 + x2) // 2,
                "cy": (y1 + y2) // 2,
                "bounds": (x1, y1, x2, y2),
            }
        )
    return res


def tap(n: dict, wait: float = 1.0) -> None:
    sh("shell", "input", "tap", str(n["cx"]), str(n["cy"]))
    time.sleep(wait)


def tap_xy(x: int, y: int, wait: float = 1.0) -> None:
    sh("shell", "input", "tap", str(x), str(y))
    time.sleep(wait)


def shot(name: str) -> None:
    (OUT / f"{name}.png").write_bytes(
        subprocess.check_output(ADB + ["exec-out", "screencap", "-p"])
    )


def find(items: list[dict], pred):
    for n in items:
        if pred(n):
            return n
    return None


def note(msg: str) -> None:
    print(msg)
    log.append(msg)


def back_to_tree() -> None:
    xml = dump("nav")
    items = parse(xml)
    if find(items, lambda n: n["desc"] in ("Créer", "Annuler", "Enregistrer")):
        ann = find(items, lambda n: n["desc"] == "Annuler")
        if ann:
            tap(ann)
        else:
            ret = find(items, lambda n: n["desc"] == "Retour")
            if ret:
                tap(ret)
    xml = dump("nav2")
    items = parse(xml)
    ret = find(items, lambda n: n["desc"] == "Retour")
    # Only back if still in overlay with Retour and not main tree tabs alone
    if ret and not find(items, lambda n: "Inventaire" in n["desc"]):
        tap(ret)


def goto_tab(prefix: str) -> list[dict]:
    xml = dump("tab")
    items = parse(xml)
    tab = find(
        items,
        lambda n: n["desc"].startswith(prefix) and "Onglet" in n["desc"],
    )
    if tab:
        tap(tab, 1.0)
    xml = dump("tab-done")
    shot(f"tab-{prefix[:8]}")
    return parse(xml)


def main() -> None:
    back_to_tree()
    items = goto_tab("Biens")
    note(
        "biens_home="
        + str(any("M53DBien" in n["desc"] for n in items))
    )

    # Expand / collapse Support de guitare
    supp = find(
        items,
        lambda n: n["desc"].startswith("Bien-contenant")
        and "Support de guitare" in n["desc"]
        and n["click"],
    )
    aff = None
    if supp:
        for n in items:
            if n["desc"] in ("Afficher le contenu", "Masquer le contenu") and abs(
                n["cy"] - supp["cy"]
            ) < 50:
                aff = n
                break
    note(f"expand_ctrl={bool(aff)} state={aff and aff['desc']}")
    if aff:
        before = aff["desc"]
        tap(aff, 1.0)
        items = parse(dump("exp1"))
        shot("14-expand-container")
        aff2 = None
        for n in items:
            if n["desc"] in ("Afficher le contenu", "Masquer le contenu") and abs(
                n["cy"] - supp["cy"]
            ) < 80:
                aff2 = n
                break
        note(f"expand_toggle {before} -> {aff2 and aff2['desc']}")
        supp = find(
            items,
            lambda n: "Support de guitare" in n["desc"]
            and n["desc"].startswith("Bien-contenant")
            and n["click"],
        )
        if supp:
            tap(supp, 1.0)
            items = parse(dump("det1"))
            shot("15-details-container")
            note(
                "details_markers="
                + str(
                    any(
                        k in (n["desc"] + n["text"])
                        for n in items
                        for k in ("Modifier", "Qté", "Objectif", "Documents", "Photo")
                    )
                )
            )

    # STOCK
    items = goto_tab("Stock")
    note(
        "stock_nodes="
        + str(
            [
                n["desc"][:50]
                for n in items
                if n["click"] and n["desc"] and "Onglet" not in n["desc"]
            ][:12]
        )
    )
    more = find(items, lambda n: "Plus" in n["desc"])
    if more:
        tap(more, 0.8)
        items = parse(dump("stock-menu"))
        add = find(items, lambda n: n["text"] == "Ajouter" or n["desc"] == "Ajouter")
        note(f"stock_menu_add={bool(add)}")
        if add:
            tap(add, 1.0)
    items = parse(dump("stock-picker"))
    shot("17-stock-picker")
    prod = find(
        items,
        lambda n: n["click"] and n["desc"].startswith("Produit"),
    )
    if not prod:
        prod = find(items, lambda n: n["click"] and "Produit" in n["desc"])
    note(f"stock_prod_card={bool(prod)}")
    if prod:
        tap(prod, 1.3)
        tap_xy(360, 250, 0.5)
        sh("shell", "input", "text", "M53DRiz")
        time.sleep(0.4)
        sh("shell", "input", "swipe", "360", "1100", "360", "500", "250")
        time.sleep(0.5)
        items = parse(dump("stock-form"))
        btn = find(items, lambda n: n["desc"] == "Créer")
        if btn:
            tap(btn, 1.6)
        items = parse(dump("stock-created"))
        shot("19-stock-created")
        note(f"stock_M53DRiz={any('M53DRiz' in n['desc'] for n in items)}")

    items = parse(dump("stock-tree"))
    row = find(items, lambda n: "M53DRiz" in n["desc"] and n["click"])
    level = None
    if row:
        for n in items:
            if (n["text"] in ("1", "½", "¼", "0") or n["desc"] in ("1", "½", "¼", "0")) and abs(
                n["cy"] - row["cy"]
            ) < 60:
                level = n
                break
    note(f"stock_level_ctrl={level}")
    if level:
        for i in range(3):
            tap(level, 0.8)
            items = parse(dump(f"stock-lv-{i}"))
            row = find(items, lambda n: "M53DRiz" in n["desc"] and n["click"]) or row
            level = None
            for n in items:
                if (
                    n["text"] in ("1", "½", "¼", "0") or n["desc"] in ("1", "½", "¼", "0")
                ) and abs(n["cy"] - row["cy"]) < 70:
                    level = n
                    break
            note(f"stock_level_{i}={level and (level['text'] or level['desc'])}")
        shot("20-stock-level")

    # History via product form: tap row then look
    items = parse(dump("stock-before-hist"))
    row = find(items, lambda n: "M53DRiz" in n["desc"] and n["click"])
    if row:
        # trailing edit often right side
        tap_xy(min(680, row["bounds"][2] - 20), row["cy"], 1.0)
        items = parse(dump("stock-edit-try"))
        shot("21-stock-edit-try")
        hist = find(items, lambda n: "Historique" in n["desc"] + n["text"])
        note(f"stock_hist={bool(hist)}")
        if hist:
            tap(hist, 1.2)
            shot("21-stock-history")
            items = parse(dump("stock-hist"))
            note(
                "stock_hist_entries="
                + str(
                    [
                        n["text"] or n["desc"][:40]
                        for n in items
                        if n["text"] or ("changement" in n["desc"].lower())
                    ][:8]
                )
            )
            ret = find(items, lambda n: n["desc"] == "Retour")
            if ret:
                tap(ret)
            ret = find(parse(dump("stock-hist2")), lambda n: n["desc"] == "Retour")
            if ret:
                tap(ret)

    # A ACHETER
    items = goto_tab("À acheter")
    more = find(items, lambda n: "Plus" in n["desc"])
    if more:
        tap(more, 0.8)
        items = parse(dump("buy-menu"))
        add = find(items, lambda n: n["text"] == "Ajouter" or n["desc"] == "Ajouter")
        if add:
            tap(add, 1.0)
    items = parse(dump("buy-picker"))
    shot("23-tobuy-picker")
    art = find(items, lambda n: n["click"] and n["desc"].startswith("Article"))
    if not art:
        art = find(items, lambda n: n["click"] and "Article" in n["desc"])
    note(f"buy_article_card={bool(art)}")
    if art:
        tap(art, 1.3)
        tap_xy(360, 250, 0.5)
        sh("shell", "input", "text", "M53DCafe")
        time.sleep(0.4)
        sh("shell", "input", "swipe", "360", "1100", "360", "500", "250")
        time.sleep(0.5)
        items = parse(dump("buy-form"))
        btn = find(items, lambda n: n["desc"] == "Créer")
        if btn:
            tap(btn, 1.6)
        items = parse(dump("buy-created"))
        shot("24-tobuy-created")
        note(f"buy_M53DCafe={any('M53DCafe' in n['desc'] for n in items)}")

    items = parse(dump("buy-tree"))
    need = find(items, lambda n: "M53DCafe" in n["desc"] and n["click"])
    if need:
        tap_xy(min(680, need["bounds"][2] - 20), need["cy"], 1.2)
        items = parse(dump("buy-edit"))
        shot("26-need-edit")
        achete = find(items, lambda n: n["desc"] == "Acheté" or n["text"] == "Acheté")
        note(f"buy_achete={bool(achete)}")
        if achete:
            tap(achete, 1.3)
            items = parse(dump("buy-acquire"))
            shot("27-acquire")
            note(
                "acquire_ui="
                + str(
                    [
                        n["desc"][:40] or n["text"]
                        for n in items
                        if n["click"] and (n["desc"] or n["text"])
                    ][:25]
                )
            )
            # Prefer Biens destination then confirm
            dest = find(
                items,
                lambda n: (n["text"] == "Biens" or n["desc"] == "Biens") and n["click"],
            )
            if dest:
                tap(dest, 0.7)
            conf = find(
                items,
                lambda n: n["desc"]
                in ("Confirmer", "Enregistrer", "Créer", "Confirmer l’achat")
                or n["text"] in ("Confirmer", "Enregistrer", "Créer"),
            )
            if not conf:
                # filled button near bottom
                conf = find(
                    items,
                    lambda n: n["click"]
                    and n["cy"] > 1200
                    and n["cls"].endswith("Button"),
                )
            note(f"acquire_confirm={bool(conf)}")
            if conf:
                tap(conf, 1.8)
            items = parse(dump("buy-after-acq"))
            shot("28-after-acquire-biens")
            note(
                "after_acq="
                + str([n["desc"][:60] for n in items if "M53D" in n["desc"]])
            )

    # Second need -> Stock associate (create M53DCafe2)
    items = goto_tab("À acheter")
    more = find(items, lambda n: "Plus" in n["desc"])
    if more:
        tap(more, 0.8)
        items = parse(dump("buy2-menu"))
        add = find(items, lambda n: n["text"] == "Ajouter" or n["desc"] == "Ajouter")
        if add:
            tap(add, 1.0)
    items = parse(dump("buy2-picker"))
    art = find(items, lambda n: n["click"] and "Article" in n["desc"])
    if art:
        tap(art, 1.2)
        tap_xy(360, 250, 0.5)
        sh("shell", "input", "text", "M53DCafe2")
        time.sleep(0.3)
        sh("shell", "input", "swipe", "360", "1100", "360", "500", "250")
        time.sleep(0.4)
        items = parse(dump("buy2-form"))
        btn = find(items, lambda n: n["desc"] == "Créer")
        if btn:
            tap(btn, 1.5)
    items = parse(dump("buy2-created"))
    need = find(items, lambda n: "M53DCafe2" in n["desc"] and n["click"])
    note(f"buy2_created={bool(need)}")
    if need:
        tap_xy(min(680, need["bounds"][2] - 20), need["cy"], 1.2)
        items = parse(dump("buy2-edit"))
        achete = find(items, lambda n: n["desc"] == "Acheté" or n["text"] == "Acheté")
        if achete:
            tap(achete, 1.3)
            items = parse(dump("buy2-acq"))
            shot("29-acquire-stock")
            dest = find(
                items,
                lambda n: (n["text"] == "Stock" or n["desc"] == "Stock") and n["click"],
            )
            if dest:
                tap(dest, 0.8)
            items = parse(dump("buy2-acq-stock"))
            note(
                "acq_stock_ui="
                + str(
                    [
                        (n["text"] or n["desc"])[:50]
                        for n in items
                        if n["click"] and (n["text"] or n["desc"])
                    ][:30]
                )
            )
            # Associate existing product options
            keep = find(
                items,
                lambda n: "conserver" in (n["text"] + n["desc"]).lower()
                or "Associer" in n["text"] + n["desc"],
            )
            if keep:
                tap(keep, 0.8)
            items = parse(dump("buy2-assoc"))
            riz = find(items, lambda n: "M53DRiz" in n["desc"] + n["text"] and n["click"])
            if riz:
                tap(riz, 0.8)
            conf = find(
                items,
                lambda n: n["desc"] in ("Confirmer", "Enregistrer", "Créer")
                or n["text"] in ("Confirmer", "Enregistrer", "Créer"),
            )
            if conf:
                tap(conf, 1.8)
            items = parse(dump("buy2-done"))
            shot("30-after-acquire-stock")
            note(
                "after_stock_acq="
                + str([n["desc"][:60] for n in items if "M53D" in n["desc"]])
            )

    # Persistence: force-stop + relaunch
    sh("shell", "am", "force-stop", "io.github.cometom3.inventory")
    time.sleep(1)
    sh(
        "shell",
        "am",
        "start",
        "-n",
        "io.github.cometom3.inventory/.MainActivity",
    )
    time.sleep(4)
    items = parse(dump("persist"))
    shot("31-persist")
    blob = "\n".join(n["desc"] + n["text"] for n in items)
    note(f"persist_M53DBien={'M53DBien' in blob}")
    note(f"persist_M53DRiz={'M53DRiz' in blob}")
    note(f"persist_M53DCafe={'M53DCafe' in blob}")

    # Settings backup entry reachable?
    more = find(items, lambda n: "Plus" in n["desc"])
    if more:
        tap(more, 0.8)
        items = parse(dump("menu-end"))
        settings = find(
            items, lambda n: n["text"] == "Paramètres" or n["desc"] == "Paramètres"
        )
        note(f"settings_entry={bool(settings)}")
        if settings:
            tap(settings, 1.2)
            items = parse(dump("settings"))
            shot("32-settings")
            note(
                "settings_backup_ui="
                + str(
                    [
                        n["text"] or n["desc"][:50]
                        for n in items
                        if "sauveg" in (n["text"] + n["desc"]).lower()
                        or "restau" in (n["text"] + n["desc"]).lower()
                        or "export" in (n["text"] + n["desc"]).lower()
                    ]
                )
            )

    (OUT / "log.txt").write_text("\n".join(log), encoding="utf-8")
    print("DONE", len(log))


if __name__ == "__main__":
    main()
