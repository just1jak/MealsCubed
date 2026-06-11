"use strict";

const STORAGE_KEY = "mealcube.companionPlanner.v1";
const imagePool = {
  hero: "../meals-cubed/meals-cubed/Assets/mealcube-hero.png",
  bowls: "../meals-cubed/meals-cubed/Assets/bowl-plan.png",
  cubes: "../meals-cubed/meals-cubed/Assets/cube-trays.png",
  ready: "../meals-cubed/meals-cubed/Assets/Generated image 1.png"
};

const $ = (selector) => document.querySelector(selector);

function slug(value) {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function escapeHTML(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

function addDays(date, days) {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
}

function parseISODate(value) {
  const [year, month, day] = value.split("-").map(Number);
  return new Date(year, month - 1, day);
}

function formatDate(date) {
  return date.toLocaleDateString(undefined, {
    weekday: "short",
    month: "short",
    day: "numeric"
  });
}

function bowl(
  name,
  theme,
  summary,
  base,
  proteinSource,
  vegetables,
  sauce,
  fresh,
  calories,
  protein,
  fiber,
  vegetarian = false,
  prepMinutes = 20
) {
  const image =
    theme === "Tex-Mex" || theme === "Lean Turkey" || theme === "Chicken"
      ? imagePool.bowls
      : theme === "Cozy Vegetarian" || theme === "Tofu + Beans"
        ? imagePool.cubes
        : imagePool.ready;

  return {
    id: slug(name),
    type: "meal",
    name,
    theme,
    summary,
    calories,
    protein,
    fiber,
    prepMinutes,
    vegetarian,
    servings: 6,
    cubeSize: "2 cup",
    image,
    ingredients: [
      `4 cups cooked ${base}`,
      `2 lb cooked lean protein or 4 cups plant protein: ${proteinSource}`,
      `6 cups ${vegetables}`,
      `1 1/2 cups sauce plus 2 Tbsp seasoning: ${sauce}`,
      `2 cups fresh finish: ${fresh}`
    ],
    instructions: [
      "Cook 1 1/2 cups dry grain, or measure 4 cups cooked prepared base.",
      "Warm 2 lb cooked lean protein or 4 cups plant protein with 6 cups vegetables in one pot or skillet.",
      "Stir in 1 1/2 cups sauce and 2 Tbsp seasoning, then simmer until the mixture is thick.",
      "Fold in the cooked base, taste, and adjust seasoning.",
      "Portion into six 2-cup Souper Cube portions.",
      "Freeze, reheat, and add about 1/3 cup fresh finish per bowl after warming."
    ],
    shopping: [
      { group: "Base", item: `4 cups cooked ${base}` },
      { group: "Protein", item: `2 lb cooked lean protein or 4 cups plant protein: ${proteinSource}` },
      { group: "Vegetables", item: `6 cups ${vegetables}` },
      { group: "Sauce", item: `1 1/2 cups sauce plus 2 Tbsp seasoning: ${sauce}` },
      { group: "Fresh", item: `2 cups ${fresh}` }
    ]
  };
}

function snack(name, summary, ingredients, instructions, calories, protein, fiber, vegetarian = true, prepMinutes = 5) {
  return {
    id: slug(name),
    type: "snack",
    name,
    theme: "Healthy Snacks",
    summary,
    calories,
    protein,
    fiber,
    prepMinutes,
    vegetarian,
    servings: 1,
    cubeSize: "none",
    image: imagePool.hero,
    ingredients,
    instructions: [instructions],
    shopping: ingredients.map((item) => ({ group: "Snacks", item }))
  };
}

const bowlCatalog = [
  bowl("Smoky Black Bean Burrito Bowl", "Tex-Mex", "Black beans, quinoa, corn, peppers, and smoky salsa for a dump-and-stir burrito bowl.", "quinoa or brown rice", "black beans plus optional nonfat Greek yogurt after reheating", "frozen corn, bell peppers, onion, and spinach", "salsa, cumin, smoked paprika, chili powder, and lime", "cabbage slaw, cilantro, and avocado", 520, 28, 18, true, 18),
  bowl("Chipotle Chicken Quinoa Bowl", "Tex-Mex", "Rotisserie-style chicken, quinoa, beans, and chipotle salsa with almost no chopping.", "quinoa", "shredded chicken breast and pinto beans", "frozen peppers, onions, corn, and zucchini", "chipotle salsa, cumin, garlic, and oregano", "lime, pico de gallo, and lettuce", 610, 52, 13, false, 20),
  bowl("Turkey Taco Sweet Potato Bowl", "Tex-Mex", "Lean turkey taco filling with sweet potato and beans for a hearty freezer bowl.", "roasted sweet potatoes", "lean ground turkey and black beans", "frozen peppers, onions, and spinach", "taco seasoning, salsa roja, and lime", "shredded lettuce and Greek yogurt", 640, 50, 15, false, 22),
  bowl("Salsa Verde Chicken Rice Bowl", "Tex-Mex", "Chicken, brown rice, white beans, and salsa verde in one bright reheatable bowl.", "brown rice", "shredded chicken breast and white beans", "zucchini, spinach, peppers, and onion", "salsa verde, cumin, garlic, and lime", "cilantro, cabbage, and jalapeno", 590, 55, 12, false, 20),
  bowl("Lentil Fajita Bowl", "Tex-Mex", "Lentils, fajita vegetables, brown rice, and salsa for a low-lift vegetarian bowl.", "brown rice", "brown lentils and pinto beans", "frozen fajita peppers, onion, spinach, and corn", "salsa, chili powder, cumin, and smoked paprika", "lime, cilantro, and avocado", 560, 27, 20, true, 20),
  bowl("Pinto Bean Corn Barley Bowl", "Tex-Mex", "Barley, pinto beans, corn, and enchilada sauce for a freezer-friendly comfort bowl.", "barley", "pinto beans and optional edamame", "corn, peppers, onions, and kale", "red enchilada sauce, cumin, garlic, and lime", "scallions and cabbage slaw", 540, 25, 19, true, 18),

  bowl("Lemon Chickpea Farro Bowl", "Mediterranean", "Chickpeas, farro, spinach, and lemon herbs for an easy Mediterranean bowl.", "farro", "chickpeas and white beans", "spinach, zucchini, roasted peppers, and onion", "lemon, garlic, oregano, and olive oil", "cucumber, tomato, parsley, and yogurt", 560, 25, 17, true, 18),
  bowl("Chicken Tzatziki Quinoa Bowl", "Mediterranean", "Lemon chicken, quinoa, white beans, and vegetables finished with quick tzatziki.", "quinoa", "chicken breast and white beans", "spinach, zucchini, peppers, and onion", "lemon, oregano, garlic, and dill", "tzatziki, cucumber, and tomato", 600, 56, 11, false, 20),
  bowl("Turkey Kofta Lentil Bowl", "Mediterranean", "Lean turkey, lentils, warm spices, and barley for a kofta-inspired freezer bowl.", "barley", "lean ground turkey and lentils", "spinach, tomato, onion, and zucchini", "cumin, coriander, garlic, tomato paste, and lemon", "parsley, cucumber, and yogurt sauce", 650, 54, 16, false, 22),
  bowl("Greek White Bean Orzo Bowl", "Mediterranean", "White beans, orzo, spinach, and lemon tomato sauce for a fast vegetarian bowl.", "whole-wheat or chickpea orzo", "cannellini beans", "spinach, zucchini, tomatoes, and onion", "crushed tomato, lemon, garlic, oregano, and dill", "cucumber, parsley, and a little feta if desired", 540, 27, 15, true, 18),
  bowl("Harissa Tofu Couscous Bowl", "Mediterranean", "Tofu, chickpeas, couscous, and harissa vegetables with a bright lemon finish.", "whole-wheat couscous", "extra-firm tofu and chickpeas", "cauliflower, peppers, spinach, and onion", "harissa, lemon, garlic, cumin, and tomato", "parsley, cucumber, and yogurt", 590, 34, 15, true, 20),
  bowl("Za'atar Chicken Barley Bowl", "Mediterranean", "Chicken, barley, greens, and za'atar lemon sauce for a simple high-protein bowl.", "barley", "chicken breast and chickpeas", "spinach, zucchini, carrots, and onion", "za'atar, lemon, garlic, and olive oil", "tomato, cucumber, and parsley", 610, 54, 13, false, 20),

  bowl("Gochujang Turkey Bowl", "Korean", "Lean turkey, rice, edamame, cabbage, and gochujang for a fast savory bowl.", "brown rice", "lean ground turkey and shelled edamame", "cabbage, carrots, spinach, and mushrooms", "gochujang, low-sodium soy sauce, garlic, ginger, and rice vinegar", "scallions, cucumber, and sesame seeds", 650, 52, 12, false, 20),
  bowl("Tofu Bibimbap Freezer Bowl", "Korean", "Tofu, rice, mushrooms, spinach, and carrots with a freezer-safe bibimbap sauce.", "brown rice", "extra-firm tofu and edamame", "mushrooms, carrots, spinach, zucchini, and cabbage", "gochujang, garlic, ginger, soy sauce, and rice vinegar", "cucumber, scallions, and kimchi", 590, 35, 13, true, 22),
  bowl("Chicken Kimchi Brown Rice Bowl", "Korean", "Chicken, brown rice, kimchi, cabbage, and greens for a punchy reheatable bowl.", "brown rice", "chicken breast and edamame", "cabbage, spinach, carrots, and mushrooms", "kimchi brine, gochujang, garlic, ginger, and soy sauce", "kimchi and scallions", 610, 56, 10, false, 18),
  bowl("Edamame Mushroom Japchae Bowl", "Korean", "Mushrooms, edamame, spinach, and sweet potato noodles in a low-lift japchae bowl.", "sweet potato glass noodles", "edamame and tofu", "mushrooms, spinach, carrots, cabbage, and onion", "soy sauce, garlic, ginger, sesame oil, and rice vinegar", "scallions and cucumber", 560, 30, 12, true, 22),
  bowl("Lentil Gochujang Sweet Potato Bowl", "Korean", "Lentils, sweet potatoes, cabbage, and gochujang make a hearty vegetarian bowl.", "roasted sweet potatoes", "brown lentils and edamame", "cabbage, carrots, spinach, and mushrooms", "gochujang, garlic, ginger, rice vinegar, and soy sauce", "cucumber and scallions", 580, 31, 18, true, 20),
  bowl("Sesame Turkey Cauliflower Rice Bowl", "Korean", "Lean turkey, cauliflower rice, edamame, and sesame sauce for a lighter bowl.", "cauliflower rice and brown rice blend", "lean ground turkey and edamame", "cabbage, carrots, spinach, and mushrooms", "soy sauce, garlic, ginger, sesame oil, and vinegar", "scallions and cucumber", 560, 52, 11, false, 18),

  bowl("Lentil Dal Bowl", "Indian", "Red lentils, brown rice, spinach, and warming spices in a one-pot dal bowl.", "brown rice", "red lentils and optional edamame", "spinach, cauliflower, carrots, and onion", "turmeric, cumin, garlic, ginger, tomato, and garam masala", "cilantro, lime, and yogurt", 560, 28, 18, true, 20),
  bowl("Chickpea Tikka Masala Bowl", "Indian", "Chickpeas, quinoa, cauliflower, and tikka sauce without a high-effort curry night.", "quinoa", "chickpeas and tofu", "cauliflower, spinach, peas, and onion", "tomato, tikka masala spices, garlic, ginger, and light yogurt", "cilantro and cucumber", 610, 34, 17, true, 20),
  bowl("Chicken Saag Brown Rice Bowl", "Indian", "Chicken, spinach, rice, and tomato spices for a high-protein saag-inspired bowl.", "brown rice", "chicken breast and lentils", "spinach, onion, cauliflower, and peas", "tomato, garlic, ginger, cumin, coriander, and garam masala", "cilantro and yogurt", 620, 58, 13, false, 22),
  bowl("Tofu Pea Curry Bowl", "Indian", "Tofu, peas, rice, and a tomato curry sauce for a simple freezer bowl.", "brown rice", "extra-firm tofu and green peas", "spinach, cauliflower, carrots, and onion", "tomato, curry powder, turmeric, garlic, and ginger", "cilantro, lime, and yogurt", 570, 32, 14, true, 18),
  bowl("Turkey Keema Quinoa Bowl", "Indian", "Lean turkey, quinoa, peas, and tomato spices for a quick keema-style bowl.", "quinoa", "lean ground turkey and lentils", "peas, carrots, spinach, and onion", "tomato, cumin, coriander, turmeric, garlic, and ginger", "cilantro, cucumber, and yogurt", 650, 55, 14, false, 20),
  bowl("Rajma Kidney Bean Bowl", "Indian", "Kidney beans, barley, tomato, and spices for a hands-off rajma-inspired bowl.", "barley", "kidney beans and lentils", "spinach, carrots, cauliflower, and onion", "tomato, cumin, garam masala, garlic, and ginger", "cilantro and lime", 550, 27, 21, true, 20),

  bowl("Thai Peanut Chicken Noodle Bowl", "Thai", "Chicken, rice noodles, vegetables, and light peanut sauce for a takeout-style bowl.", "brown rice noodles", "chicken breast and edamame", "cabbage, carrots, peppers, and spinach", "peanut powder, lime, soy sauce, garlic, ginger, and chili paste", "cilantro, cucumber, and lime", 660, 56, 10, false, 20),
  bowl("Tofu Red Curry Rice Bowl", "Thai", "Tofu, brown rice, vegetables, and red curry sauce with light coconut milk.", "brown rice", "extra-firm tofu and edamame", "broccoli, peppers, spinach, carrots, and onion", "red curry paste, light coconut milk, lime, garlic, and ginger", "cilantro and basil", 620, 34, 13, true, 20),
  bowl("Turkey Basil Veg Bowl", "Thai", "Lean turkey, vegetables, brown rice, and basil-garlic sauce for a fast bowl.", "brown rice", "lean ground turkey", "green beans, peppers, carrots, spinach, and onion", "soy sauce, garlic, ginger, chili paste, and basil", "basil, lime, and cucumber", 610, 50, 10, false, 18),
  bowl("Chickpea Green Curry Bowl", "Thai", "Chickpeas, quinoa, vegetables, and green curry for a vegetarian freezer bowl.", "quinoa", "chickpeas and edamame", "broccoli, peas, spinach, peppers, and onion", "green curry paste, light coconut milk, lime, garlic, and ginger", "cilantro, basil, and cucumber", 600, 31, 16, true, 20),
  bowl("Chicken Coconut-Lite Sweet Potato Bowl", "Thai", "Chicken, sweet potato, greens, and a light coconut curry sauce for easy reheating.", "roasted sweet potatoes", "chicken breast and lentils", "spinach, peppers, carrots, and onion", "yellow curry paste, light coconut milk, lime, garlic, and ginger", "cilantro and lime", 650, 55, 13, false, 22),
  bowl("Edamame Lime Slaw Rice Bowl", "Thai", "Edamame, rice, cabbage, carrots, and lime sauce for a bright vegetarian bowl.", "brown rice", "edamame and tofu", "cabbage, carrots, peppers, spinach, and onion", "lime, soy sauce, garlic, ginger, chili paste, and peanut powder", "cilantro, cucumber, and lime", 580, 34, 13, true, 18),

  bowl("Miso Tofu Rice Bowl", "Japanese", "Tofu, rice, mushrooms, edamame, and miso sauce for a calm freezer bowl.", "brown rice", "extra-firm tofu and edamame", "mushrooms, spinach, carrots, cabbage, and onion", "miso, soy sauce, rice vinegar, garlic, and ginger", "scallions, cucumber, and sesame", 580, 34, 12, true, 18),
  bowl("Teriyaki Turkey Barley Bowl", "Japanese", "Lean turkey, barley, vegetables, and light teriyaki sauce for a hearty bowl.", "barley", "lean ground turkey and edamame", "broccoli, carrots, spinach, mushrooms, and onion", "low-sugar teriyaki, garlic, ginger, and rice vinegar", "scallions and cucumber", 630, 52, 14, false, 20),
  bowl("Chicken Edamame Sushi Bowl", "Japanese", "Chicken, brown rice, edamame, carrots, and sushi-bowl seasonings.", "brown rice", "chicken breast and edamame", "carrots, cabbage, spinach, and mushrooms", "rice vinegar, soy sauce, ginger, garlic, and a little sesame oil", "cucumber, nori strips, and scallions", 600, 56, 10, false, 18),
  bowl("Mushroom Soba Protein Bowl", "Japanese", "Soba, tofu, mushrooms, and greens with ginger miso sauce.", "soba noodles", "tofu and edamame", "mushrooms, spinach, cabbage, carrots, and onion", "miso, ginger, garlic, soy sauce, and rice vinegar", "scallions and cucumber", 590, 35, 12, true, 20),
  bowl("Ginger Chicken Brown Rice Bowl", "Japanese", "Chicken, brown rice, carrots, cabbage, and ginger-soy sauce.", "brown rice", "chicken breast", "cabbage, carrots, mushrooms, spinach, and onion", "ginger, garlic, soy sauce, rice vinegar, and sesame oil", "scallions and cucumber", 580, 54, 9, false, 18),
  bowl("White Bean Miso Sweet Potato Bowl", "Japanese", "White beans, sweet potatoes, spinach, and miso ginger sauce.", "roasted sweet potatoes", "white beans and edamame", "spinach, mushrooms, carrots, and cabbage", "miso, ginger, garlic, rice vinegar, and soy sauce", "scallions and cucumber", 570, 29, 17, true, 20),

  bowl("Lentil Shepherd Bowl", "Cozy Vegetarian", "Lentils, peas, carrots, mushrooms, and sweet potato for a freezer shepherd bowl.", "sweet potato mash", "lentils and white beans", "peas, carrots, mushrooms, spinach, and onion", "tomato paste, garlic, thyme, rosemary, and vegetable broth", "parsley and black pepper", 560, 27, 21, true, 22),
  bowl("Mushroom Barley Umami Bowl", "Cozy Vegetarian", "Mushrooms, barley, white beans, and greens in a savory low-effort bowl.", "barley", "white beans and edamame", "mushrooms, spinach, carrots, celery, and onion", "miso, thyme, garlic, and low-sodium broth", "parsley and lemon", 540, 28, 18, true, 20),
  bowl("Red Bean Chili Mac Bowl", "Cozy Vegetarian", "Beans, chickpea pasta, tomato, and chili spices for comfort-food freezer cubes.", "chickpea pasta", "kidney beans and pinto beans", "tomatoes, peppers, spinach, corn, and onion", "crushed tomato, chili powder, cumin, garlic, and paprika", "scallions and Greek yogurt", 620, 34, 20, true, 20),
  bowl("Split Pea Sweet Potato Bowl", "Cozy Vegetarian", "Split peas, sweet potato, carrots, and greens for an easy freezer stew bowl.", "sweet potato cubes", "split peas and edamame", "carrots, celery, spinach, onion, and peas", "low-sodium broth, garlic, thyme, and smoked paprika", "parsley and lemon", 550, 30, 22, true, 20),
  bowl("Tomato Chickpea Polenta Bowl", "Cozy Vegetarian", "Chickpeas, polenta, tomato, and greens for a soft, cozy freezer bowl.", "firm polenta cubes", "chickpeas and white beans", "spinach, zucchini, mushrooms, and onion", "crushed tomato, garlic, basil, oregano, and red pepper", "parsley and a spoon of yogurt", 570, 26, 17, true, 18),
  bowl("Butternut Black Bean Bowl", "Cozy Vegetarian", "Butternut squash, black beans, quinoa, and greens with smoky spices.", "quinoa", "black beans and edamame", "butternut squash, spinach, peppers, and onion", "smoked paprika, cumin, garlic, tomato, and lime", "cilantro and cabbage slaw", 590, 31, 19, true, 22),

  bowl("Turkey Marinara Chickpea Pasta Bowl", "Lean Turkey", "Lean turkey, chickpea pasta, marinara, mushrooms, and spinach.", "chickpea pasta", "lean ground turkey", "mushrooms, spinach, zucchini, carrots, and onion", "low-sugar marinara, garlic, oregano, and basil", "parsley and red pepper", 680, 58, 15, false, 20),
  bowl("Turkey Verde Rice Bowl", "Lean Turkey", "Lean turkey, brown rice, white beans, and salsa verde in a bowl format.", "brown rice", "lean ground turkey and white beans", "peppers, zucchini, spinach, corn, and onion", "salsa verde, cumin, garlic, and lime", "cilantro and cabbage", 640, 52, 13, false, 18),
  bowl("Turkey Mushroom Stroganoff Bowl", "Lean Turkey", "Turkey, mushrooms, barley, and yogurt-finished stroganoff flavors.", "barley", "lean ground turkey", "mushrooms, spinach, carrots, celery, and onion", "low-sodium broth, Dijon, garlic, thyme, and nonfat Greek yogurt after reheating", "parsley and black pepper", 620, 54, 12, false, 22),
  bowl("Turkey Shawarma Grain Bowl", "Lean Turkey", "Shawarma-spiced turkey, quinoa, chickpeas, and vegetables.", "quinoa", "lean ground turkey and chickpeas", "spinach, peppers, zucchini, onion, and carrots", "cumin, coriander, paprika, garlic, lemon, and yogurt finish", "cucumber, tomato, and parsley", 650, 55, 14, false, 20),
  bowl("Turkey Chili Corn Bowl", "Lean Turkey", "Lean turkey chili with corn, beans, brown rice, and smoky spices.", "brown rice", "lean ground turkey, black beans, and kidney beans", "corn, peppers, spinach, zucchini, and onion", "crushed tomato, chili powder, cumin, garlic, and paprika", "lime, cilantro, and cabbage", 670, 56, 18, false, 20),
  bowl("Turkey Enchilada Quinoa Bowl", "Lean Turkey", "Turkey, quinoa, beans, vegetables, and enchilada sauce with minimal prep.", "quinoa", "lean ground turkey and pinto beans", "peppers, corn, spinach, zucchini, and onion", "red enchilada sauce, cumin, garlic, and oregano", "cilantro, lime, and lettuce", 650, 54, 15, false, 18),

  bowl("Lemon Dijon Chicken Barley Bowl", "Chicken", "Chicken, barley, greens, and lemon Dijon sauce for a clean freezer bowl.", "barley", "chicken breast and white beans", "spinach, carrots, celery, zucchini, and onion", "lemon, Dijon, garlic, thyme, and low-sodium broth", "parsley and cucumber", 610, 56, 13, false, 20),
  bowl("Chicken White Bean Kale Bowl", "Chicken", "Chicken, white beans, kale, quinoa, and lemon herbs in one batch.", "quinoa", "chicken breast and white beans", "kale, zucchini, carrots, celery, and onion", "lemon, garlic, rosemary, thyme, and broth", "parsley and lemon", 620, 58, 14, false, 20),
  bowl("BBQ Chicken Lentil Bowl", "Chicken", "Chicken, lentils, sweet potato, and a low-sugar BBQ sauce for comfort prep.", "roasted sweet potatoes", "chicken breast and lentils", "corn, spinach, peppers, and onion", "low-sugar BBQ sauce, smoked paprika, garlic, and vinegar", "cabbage slaw and scallions", 650, 56, 16, false, 22),
  bowl("Chicken Pesto Farro Bowl", "Chicken", "Chicken, farro, white beans, spinach, and light pesto flavors.", "farro", "chicken breast and white beans", "spinach, zucchini, mushrooms, and onion", "light pesto, lemon, garlic, and low-sodium broth", "tomato, basil, and lemon", 640, 56, 13, false, 18),
  bowl("Chicken Ginger Veg Rice Bowl", "Chicken", "Chicken, rice, mixed vegetables, and ginger-garlic sauce.", "brown rice", "chicken breast and edamame", "broccoli, carrots, cabbage, spinach, and onion", "ginger, garlic, soy sauce, rice vinegar, and a little sesame oil", "scallions and cucumber", 610, 56, 10, false, 18),
  bowl("Chicken Mole-ish Black Bean Bowl", "Chicken", "Chicken, black beans, rice, cocoa-chili tomato sauce, and peppers.", "brown rice", "chicken breast and black beans", "peppers, spinach, zucchini, corn, and onion", "tomato, chili powder, cumin, cinnamon, cocoa powder, and garlic", "cilantro and lime", 640, 55, 15, false, 22),

  bowl("Tofu Black Bean Sofrito Bowl", "Tofu + Beans", "Tofu, black beans, rice, sofrito, and peppers for a bright freezer bowl.", "brown rice", "extra-firm tofu and black beans", "peppers, spinach, zucchini, corn, and onion", "sofrito, cumin, garlic, tomato, and lime", "cilantro and cabbage", 590, 34, 16, true, 20),
  bowl("Tofu Lentil Peanut Bowl", "Tofu + Beans", "Tofu, lentils, vegetables, and a light peanut-lime sauce.", "quinoa", "extra-firm tofu and lentils", "cabbage, carrots, spinach, peppers, and onion", "peanut powder, lime, garlic, ginger, and soy sauce", "cilantro and cucumber", 620, 38, 17, true, 20),
  bowl("Chickpea Edamame Power Bowl", "Tofu + Beans", "Chickpeas, edamame, farro, greens, and lemon tahini-style sauce.", "farro", "chickpeas and edamame", "spinach, carrots, cucumber after reheating, and peppers", "lemon, garlic, tahini, and water to thin", "parsley and cucumber", 620, 35, 18, true, 18),
  bowl("White Bean Tomato Tofu Bowl", "Tofu + Beans", "Tofu, white beans, barley, tomato, and greens for an easy savory bowl.", "barley", "extra-firm tofu and white beans", "spinach, zucchini, mushrooms, carrots, and onion", "crushed tomato, garlic, basil, oregano, and red pepper", "parsley and lemon", 580, 34, 17, true, 20),
  bowl("Black Eyed Pea Tofu Bowl", "Tofu + Beans", "Black eyed peas, tofu, rice, greens, and smoky tomato seasoning.", "brown rice", "extra-firm tofu and black eyed peas", "collards or spinach, peppers, carrots, and onion", "smoked paprika, garlic, tomato, vinegar, and thyme", "scallions and hot sauce", 590, 34, 16, true, 20),
  bowl("Three Bean Tofu Chili Bowl", "Tofu + Beans", "Tofu, three beans, quinoa, tomatoes, and chili spices for a prep staple.", "quinoa", "tofu, black beans, kidney beans, and pinto beans", "peppers, zucchini, spinach, corn, and onion", "crushed tomato, chili powder, cumin, garlic, and smoked paprika", "cilantro, lime, and cabbage", 620, 38, 20, true, 22)
];

const snackCatalog = [
  snack("Greek Yogurt Berry Crunch", "High-protein yogurt with berries and a little crunch.", ["1 cup nonfat Greek yogurt", "1/2 cup berries", "1/4 cup high-fiber cereal or oats", "1 Tbsp chia seeds", "1/4 tsp cinnamon"], "Layer yogurt, berries, cereal or oats, chia, and cinnamon.", 250, 24, 8),
  snack("Apple Almond Butter Plate", "Apple slices with measured almond butter and cinnamon.", ["1 medium apple", "1 Tbsp almond butter", "1/4 tsp cinnamon"], "Slice apple and serve with one measured spoon of almond butter.", 230, 6, 7),
  snack("Cottage Cheese Pineapple Cup", "Lean protein with fruit for a fast sweet snack.", ["1 cup low-fat cottage cheese", "1/2 cup pineapple", "1 Tbsp ground flaxseed"], "Spoon cottage cheese into a bowl and top with pineapple and flaxseed.", 240, 26, 4),
  snack("Hummus Veggie Box", "Fiber-rich vegetables with hummus for crunch.", ["1/4 cup hummus", "1 cup baby carrots", "1/2 cup cucumber slices", "1/2 cup bell pepper strips", "1/2 cup cherry tomatoes"], "Pack hummus with sliced vegetables.", 220, 8, 9),
  snack("Edamame Sea Salt Cup", "Simple high-protein edamame with lemon.", ["1 cup shelled edamame", "1 lemon wedge", "1/8 tsp sea salt", "Pinch red pepper flakes"], "Steam edamame, season lightly, and chill or eat warm.", 190, 18, 8),
  snack("Turkey Cucumber Rollups", "Lean turkey wrapped with cucumber and mustard.", ["4 oz sliced turkey breast", "1/2 cup cucumber strips", "1 Tbsp mustard", "6 whole-grain crackers"], "Roll turkey around cucumber strips and serve with crackers.", 210, 24, 3, false),
  snack("Tuna Avocado Rice Cakes", "Lean tuna, avocado, and rice cakes for a filling snack.", ["1 tuna packet, about 2.6 oz", "1/4 avocado", "2 brown rice cakes", "1 tsp lemon juice", "Black pepper to taste"], "Mash tuna with avocado and lemon, then spread over rice cakes.", 260, 25, 5, false),
  snack("Protein Oats Cup", "No-cook oats with protein and berries.", ["1/2 cup oats", "1 scoop protein powder", "1/2 cup nonfat Greek yogurt", "1/2 cup berries", "1 Tbsp chia seeds"], "Stir ingredients together and chill.", 310, 30, 8),
  snack("Chia Berry Pudding", "Make-ahead chia pudding with berries.", ["2 Tbsp chia seeds", "1/2 cup unsweetened almond milk", "1/2 cup berries", "1/4 tsp vanilla", "1/4 tsp cinnamon"], "Stir chia with almond milk, vanilla, and cinnamon. Chill and top with berries.", 220, 8, 13),
  snack("Egg Fruit Plate", "Boiled eggs with fruit for a portable snack.", ["2 hard-boiled eggs", "1/2 cup grapes or berries", "1 cup baby carrots"], "Pack eggs with fruit and carrots.", 240, 14, 5),
  snack("Roasted Chickpea Crunch", "Crunchy chickpeas with smoky seasoning.", ["1 cup chickpeas, drained and rinsed", "Olive oil spray", "1/2 tsp smoked paprika", "1/4 tsp garlic powder", "1 lemon wedge"], "Season chickpeas and roast or air fry until crisp.", 210, 10, 9),
  snack("Salsa Cottage Cheese Bowl", "Cottage cheese with salsa and vegetables.", ["1 cup low-fat cottage cheese", "1/4 cup salsa", "1/2 cup bell pepper strips", "1/2 cup cucumber slices", "1 Tbsp chopped cilantro"], "Top cottage cheese with salsa, chopped vegetables, and cilantro.", 210, 26, 4),
  snack("Smoked Salmon Cucumber Stack", "Salmon, cucumber, and yogurt-dill topping.", ["2 oz smoked salmon", "1 cup cucumber rounds", "2 Tbsp nonfat Greek yogurt", "1 tsp chopped dill", "1 lemon wedge"], "Top cucumber rounds with salmon, yogurt, dill, and lemon.", 190, 22, 2, false),
  snack("Banana Peanut Yogurt Bowl", "Greek yogurt, banana, and peanut powder.", ["1 cup nonfat Greek yogurt", "1 small banana", "2 Tbsp peanut powder", "1/4 tsp cinnamon"], "Top yogurt with sliced banana, peanut powder, and cinnamon.", 270, 26, 5),
  snack("Black Bean Dip Veggie Cup", "Quick black bean dip with crunchy vegetables.", ["1/2 cup black beans, drained and rinsed", "1/4 cup salsa", "1 tsp lime juice", "1 cup baby carrots", "1/2 cup bell pepper strips"], "Mash beans with salsa and lime, then serve with vegetables.", 230, 11, 13),
  snack("Trail Mix Portion Pack", "Measured nuts, pumpkin seeds, and fruit.", ["1 Tbsp almonds", "1 Tbsp pumpkin seeds", "2 Tbsp unsweetened dried fruit", "1/4 cup high-fiber cereal"], "Portion into small snack bags or containers.", 240, 8, 5),
  snack("Tofu Chocolate Pudding", "Silken tofu blended into a higher-protein pudding.", ["1/2 cup silken tofu", "1 Tbsp cocoa powder", "1 tsp maple syrup", "1/4 tsp vanilla", "1/2 cup berries"], "Blend tofu, cocoa, maple, and vanilla. Chill and top with berries.", 240, 15, 5),
  snack("Caprese Cottage Cheese Cup", "Cottage cheese, tomatoes, basil, and balsamic.", ["1 cup low-fat cottage cheese", "1/2 cup cherry tomatoes", "1 Tbsp chopped basil", "1 tsp balsamic vinegar", "6 whole-grain crackers"], "Top cottage cheese with tomatoes, basil, and balsamic. Serve with crackers.", 250, 25, 4),
  snack("Lentil Cucumber Salad Cup", "Ready lentils with cucumber and lemon.", ["1/2 cup cooked lentils", "1/2 cup cucumber slices", "1 tsp lemon juice", "1 Tbsp chopped parsley", "1 tsp olive oil"], "Toss lentils with cucumber, lemon, parsley, and a little olive oil.", 230, 12, 12),
  snack("Protein Smoothie Pack", "Frozen smoothie ingredients ready to blend.", ["1 scoop protein powder", "1 cup frozen berries", "1 cup spinach", "1 cup unsweetened almond milk", "1 Tbsp ground flaxseed"], "Blend ingredients with almond milk.", 280, 28, 9)
];

const catalog = [...bowlCatalog, ...snackCatalog];
const catalogById = new Map(catalog.map((recipe) => [recipe.id, recipe]));
const themes = Array.from(new Set(catalog.map((recipe) => recipe.theme)));

let state = loadState();
let filters = {
  search: "",
  type: "all",
  theme: "all",
  vegetarian: false
};

function defaultState() {
  return {
    startDate: todayISO(),
    weeks: 1,
    slots: { lunch: true, dinner: true, snack: true },
    selectedIds: [],
    plan: [],
    cartChecked: {}
  };
}

function loadState() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY));
    if (!saved || !Array.isArray(saved.selectedIds)) {
      return defaultState();
    }
    return {
      ...defaultState(),
      ...saved,
      slots: { ...defaultState().slots, ...(saved.slots || {}) },
      selectedIds: saved.selectedIds.filter((id) => catalogById.has(id)),
      plan: Array.isArray(saved.plan) ? saved.plan : [],
      cartChecked: saved.cartChecked || {}
    };
  } catch {
    return defaultState();
  }
}

function saveState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function selectedRecipes() {
  return state.selectedIds.map((id) => catalogById.get(id)).filter(Boolean);
}

function filteredRecipes() {
  const term = filters.search.trim().toLowerCase();
  return catalog.filter((recipe) => {
    if (filters.type !== "all" && recipe.type !== filters.type) return false;
    if (filters.theme !== "all" && recipe.theme !== filters.theme) return false;
    if (filters.vegetarian && !recipe.vegetarian) return false;
    if (!term) return true;
    return [
      recipe.name,
      recipe.theme,
      recipe.summary,
      recipe.ingredients.join(" ")
    ].join(" ").toLowerCase().includes(term);
  });
}

function setupControls() {
  $("#startDate").value = state.startDate;
  $("#weekCount").value = String(state.weeks);
  $("#slotLunch").checked = state.slots.lunch;
  $("#slotDinner").checked = state.slots.dinner;
  $("#slotSnack").checked = state.slots.snack;

  const themeSelect = $("#themeFilter");
  themes.forEach((theme) => {
    const option = document.createElement("option");
    option.value = theme;
    option.textContent = theme;
    themeSelect.appendChild(option);
  });

  $("#startDate").addEventListener("change", (event) => {
    state.startDate = event.target.value || todayISO();
    saveState();
    renderPlan();
  });
  $("#weekCount").addEventListener("change", (event) => {
    state.weeks = Number(event.target.value);
    saveState();
    renderStats();
  });
  $("#slotLunch").addEventListener("change", (event) => {
    state.slots.lunch = event.target.checked;
    saveState();
    renderStats();
  });
  $("#slotDinner").addEventListener("change", (event) => {
    state.slots.dinner = event.target.checked;
    saveState();
    renderStats();
  });
  $("#slotSnack").addEventListener("change", (event) => {
    state.slots.snack = event.target.checked;
    saveState();
    renderStats();
  });
  $("#searchInput").addEventListener("input", (event) => {
    filters.search = event.target.value;
    renderCatalog();
  });
  $("#typeFilter").addEventListener("change", (event) => {
    filters.type = event.target.value;
    renderCatalog();
  });
  $("#themeFilter").addEventListener("change", (event) => {
    filters.theme = event.target.value;
    renderThemeChips();
    renderCatalog();
  });
  $("#vegFilter").addEventListener("change", (event) => {
    filters.vegetarian = event.target.checked;
    renderCatalog();
  });

  document.addEventListener("click", handleClick);
  document.addEventListener("change", handleChange);
}

function renderThemeChips() {
  const counts = themes.reduce((acc, theme) => {
    acc[theme] = catalog.filter((recipe) => recipe.theme === theme).length;
    return acc;
  }, {});

  $("#themeChips").innerHTML = [
    `<button class="chip ${filters.theme === "all" ? "active" : ""}" type="button" data-theme="all">All ${catalog.length}</button>`,
    ...themes.map((theme) => `
      <button class="chip ${filters.theme === theme ? "active" : ""}" type="button" data-theme="${escapeHTML(theme)}">
        ${escapeHTML(theme)} ${counts[theme]}
      </button>
    `)
  ].join("");
}

function renderCatalog() {
  const recipes = filteredRecipes();
  const selectedSet = new Set(state.selectedIds);
  $("#catalogGrid").innerHTML = recipes.map((recipe) => {
    const selected = selectedSet.has(recipe.id);
    const measureList = recipe.ingredients.map((item) => `<li>${escapeHTML(item)}</li>`).join("");
    const instructionList = recipe.instructions.map((item) => `<li>${escapeHTML(item)}</li>`).join("");

    return `
      <article class="recipe-card ${selected ? "selected" : ""}">
        <div class="recipe-image">
          <img src="${escapeHTML(recipe.image)}" alt="${escapeHTML(recipe.name)}">
          <span class="theme-tag">${escapeHTML(recipe.theme)}</span>
          <span class="type-tag">${recipe.type === "meal" ? "Bowl" : "Snack"}</span>
        </div>
        <div class="recipe-body">
          <div class="recipe-title-row">
            <h3>${escapeHTML(recipe.name)}</h3>
            <button class="button small select-button" type="button" data-select-id="${recipe.id}" aria-pressed="${selected}">
              ${selected ? "Added" : "Add"}
            </button>
          </div>
          <p>${escapeHTML(recipe.summary)}</p>
          <div class="recipe-metrics" aria-label="${escapeHTML(recipe.name)} nutrition">
            <span><strong>${recipe.calories}</strong> cals</span>
            <span><strong>${recipe.protein}g</strong> protein</span>
            <span><strong>${recipe.fiber}g</strong> fiber</span>
            <span><strong>${recipe.prepMinutes}</strong> min</span>
          </div>
          <details>
            <summary>Measurements</summary>
            <ul class="detail-list">${measureList}</ul>
          </details>
          <details>
            <summary>Prep Steps</summary>
            <ol class="detail-list">${instructionList}</ol>
          </details>
        </div>
      </article>
    `;
  }).join("");

  if (!recipes.length) {
    $("#catalogGrid").innerHTML = `<div class="empty-state">No matching recipes.</div>`;
  }
}

function handleClick(event) {
  const selectButton = event.target.closest("[data-select-id]");
  if (selectButton) {
    toggleRecipe(selectButton.dataset.selectId);
    return;
  }

  const themeButton = event.target.closest("[data-theme]");
  if (themeButton) {
    filters.theme = themeButton.dataset.theme;
    $("#themeFilter").value = filters.theme;
    renderThemeChips();
    renderCatalog();
    return;
  }

  const action = event.target.closest("[data-action]")?.dataset.action;
  if (!action) return;

  if (action === "build") buildPlan();
  if (action === "clear-plan") clearPlan();
  if (action === "select-visible") selectVisible();
  if (action === "copy-plan") copyPlan();
  if (action === "download") downloadPlan();
  if (action === "print") window.print();
}

function handleChange(event) {
  const planSelect = event.target.closest("[data-plan-slot]");
  if (planSelect) {
    const dayIndex = Number(planSelect.dataset.dayIndex);
    const slot = planSelect.dataset.planSlot;
    state.plan[dayIndex].slots[slot] = planSelect.value;
    saveState();
    renderAll();
    return;
  }

  const cartInput = event.target.closest("[data-cart-key]");
  if (cartInput) {
    state.cartChecked[cartInput.dataset.cartKey] = cartInput.checked;
    saveState();
    renderStats();
    renderShopping();
  }
}

function toggleRecipe(id) {
  const selected = new Set(state.selectedIds);
  if (selected.has(id)) {
    selected.delete(id);
    removeRecipeFromPlan(id);
  } else {
    selected.add(id);
  }
  state.selectedIds = Array.from(selected);
  saveState();
  renderAll();
}

function removeRecipeFromPlan(id) {
  state.plan = state.plan.map((day) => ({
    ...day,
    slots: Object.fromEntries(Object.entries(day.slots || {}).map(([slot, value]) => [slot, value === id ? "" : value]))
  }));
}

function selectVisible() {
  const selected = new Set(state.selectedIds);
  filteredRecipes().forEach((recipe) => selected.add(recipe.id));
  state.selectedIds = Array.from(selected);
  saveState();
  renderAll();
  showToast("Visible recipes added.");
}

function buildPlan() {
  const selected = selectedRecipes();
  const mealOptions = selected.filter((recipe) => recipe.type === "meal");
  const snackOptions = selected.filter((recipe) => recipe.type === "snack");
  const activeSlots = Object.entries(state.slots).filter(([, active]) => active).map(([slot]) => slot);

  if (!activeSlots.length) {
    showToast("Turn on at least one slot.");
    return;
  }

  if ((state.slots.lunch || state.slots.dinner) && !mealOptions.length) {
    showToast("Add at least one meal bowl.");
    return;
  }

  if (state.slots.snack && !snackOptions.length) {
    showToast("Add at least one snack.");
    return;
  }

  const startDate = parseISODate(state.startDate || todayISO());
  const totalDays = state.weeks * 7;
  let mealIndex = 0;
  let snackIndex = 0;

  state.plan = Array.from({ length: totalDays }, (_, index) => {
    const day = addDays(startDate, index);
    const slots = {};

    if (state.slots.lunch) {
      slots.lunch = mealOptions[mealIndex % mealOptions.length]?.id || "";
      mealIndex += 1;
    }
    if (state.slots.dinner) {
      slots.dinner = mealOptions[mealIndex % mealOptions.length]?.id || "";
      mealIndex += 1;
    }
    if (state.slots.snack) {
      slots.snack = snackOptions[snackIndex % snackOptions.length]?.id || "";
      snackIndex += 1;
    }

    return {
      date: day.toISOString().slice(0, 10),
      label: formatDate(day),
      slots
    };
  });

  saveState();
  renderAll();
  showToast("Plan built.");
}

function clearPlan() {
  state.plan = [];
  saveState();
  renderAll();
  showToast("Plan cleared.");
}

function renderPlan() {
  const board = $("#planBoard");
  if (!state.plan.length) {
    board.innerHTML = `<div class="empty-state">No plan built.</div>`;
    renderStats();
    renderShopping();
    return;
  }

  const selectedMeals = selectedRecipes().filter((recipe) => recipe.type === "meal");
  const selectedSnacks = selectedRecipes().filter((recipe) => recipe.type === "snack");
  const slotLabels = { lunch: "Lunch", dinner: "Dinner", snack: "Snack" };

  board.innerHTML = state.plan.map((day, index) => {
    const date = parseISODate(day.date);
    const slots = Object.keys(day.slots || {});
    const slotRows = slots.map((slot) => {
      const options = slot === "snack" ? selectedSnacks : selectedMeals;
      const current = catalogById.get(day.slots[slot]);
      return `
        <div class="slot-row">
          <label for="slot-${index}-${slot}">${slotLabels[slot]}</label>
          <div>
            <select id="slot-${index}-${slot}" data-day-index="${index}" data-plan-slot="${slot}">
              <option value="">None</option>
              ${options.map((recipe) => `
                <option value="${recipe.id}" ${recipe.id === day.slots[slot] ? "selected" : ""}>${escapeHTML(recipe.name)}</option>
              `).join("")}
            </select>
            <div class="slot-meta">${current ? `${current.protein}g protein, ${current.fiber}g fiber, ${current.calories} cals` : "Empty slot"}</div>
          </div>
        </div>
      `;
    }).join("");

    return `
      <article class="day-card">
        <header>
          <h3>Day ${index + 1}</h3>
          <time datetime="${escapeHTML(day.date)}">${escapeHTML(formatDate(date))}</time>
        </header>
        ${slotRows}
      </article>
    `;
  }).join("");

  renderStats();
  renderShopping();
}

function getUsageCounts() {
  const counts = new Map();

  if (state.plan.length) {
    state.plan.forEach((day) => {
      Object.values(day.slots || {}).forEach((id) => {
        if (!id || !catalogById.has(id)) return;
        counts.set(id, (counts.get(id) || 0) + 1);
      });
    });
    return counts;
  }

  state.selectedIds.forEach((id) => {
    if (catalogById.has(id)) counts.set(id, 1);
  });
  return counts;
}

function buildShoppingItems() {
  const usage = getUsageCounts();
  const items = new Map();

  usage.forEach((useCount, recipeId) => {
    const recipe = catalogById.get(recipeId);
    const multiplier = recipe.type === "meal" ? Math.max(1, Math.ceil(useCount / recipe.servings)) : useCount;
    const planLabel = recipe.type === "meal"
      ? `${multiplier} batch${multiplier === 1 ? "" : "es"} for ${useCount} slot${useCount === 1 ? "" : "s"}`
      : `${useCount} serving${useCount === 1 ? "" : "s"}`;

    recipe.shopping.forEach(({ group, item }) => {
      const key = `${group}|${item}`;
      if (!items.has(key)) {
        items.set(key, { key: slug(key), group, item, recipes: [] });
      }
      items.get(key).recipes.push(`${recipe.name}: ${planLabel}`);
    });
  });

  return Array.from(items.values()).sort((a, b) => {
    const groupOrder = ["Base", "Protein", "Vegetables", "Sauce", "Fresh", "Snacks"];
    const groupDiff = groupOrder.indexOf(a.group) - groupOrder.indexOf(b.group);
    if (groupDiff !== 0) return groupDiff;
    return a.item.localeCompare(b.item);
  });
}

function renderShopping() {
  const items = buildShoppingItems();
  const cart = $("#shoppingCart");

  if (!items.length) {
    cart.innerHTML = `<div class="empty-state">No shopping items yet.</div>`;
    return;
  }

  const groups = items.reduce((acc, item) => {
    if (!acc[item.group]) acc[item.group] = [];
    acc[item.group].push(item);
    return acc;
  }, {});

  cart.innerHTML = Object.entries(groups).map(([group, groupItems]) => `
    <article class="cart-group">
      <h3>${escapeHTML(group)}</h3>
      <div class="cart-list">
        ${groupItems.map((item) => {
          const checked = Boolean(state.cartChecked[item.key]);
          return `
            <label class="cart-item ${checked ? "checked" : ""}">
              <input type="checkbox" data-cart-key="${item.key}" ${checked ? "checked" : ""}>
              <span>
                <strong>${escapeHTML(item.item)}</strong>
                <span>${escapeHTML(item.recipes.join(" | "))}</span>
              </span>
            </label>
          `;
        }).join("")}
      </div>
    </article>
  `).join("");
}

function renderStats() {
  const selected = selectedRecipes();
  const selectedMeals = selected.filter((recipe) => recipe.type === "meal").length;
  const selectedSnacks = selected.filter((recipe) => recipe.type === "snack").length;
  const usage = getUsageCounts();
  let plannedSlots = 0;
  let calories = 0;
  let protein = 0;
  let fiber = 0;

  usage.forEach((count, id) => {
    const recipe = catalogById.get(id);
    plannedSlots += count;
    calories += recipe.calories * count;
    protein += recipe.protein * count;
    fiber += recipe.fiber * count;
  });

  const days = state.plan.length || Math.max(1, state.weeks * 7);
  const cartItems = buildShoppingItems();
  const checkedItems = cartItems.filter((item) => state.cartChecked[item.key]).length;

  $("#selectedCount").textContent = selected.length;
  $("#selectedBreakdown").textContent = `${selectedMeals} meals, ${selectedSnacks} snacks`;
  $("#slotCount").textContent = plannedSlots;
  $("#slotBreakdown").textContent = state.plan.length ? `${state.plan.length} days` : "No plan built";
  $("#avgProtein").textContent = `${Math.round(protein / days)}g`;
  $("#avgNutrition").textContent = `${Math.round(calories / days)} cals, ${Math.round(fiber / days)}g fiber`;
  $("#cartCount").textContent = cartItems.length;
  $("#cartProgress").textContent = `${checkedItems} checked`;
}

function copyPlan() {
  const text = buildExportText();
  if (!text) {
    showToast("No plan to copy.");
    return;
  }

  if (navigator.clipboard?.writeText) {
    navigator.clipboard.writeText(text)
      .then(() => showToast("Plan copied."))
      .catch(() => fallbackCopy(text));
    return;
  }

  fallbackCopy(text);
}

function fallbackCopy(text) {
  const textarea = document.createElement("textarea");
  textarea.value = text;
  textarea.setAttribute("readonly", "");
  textarea.style.position = "fixed";
  textarea.style.left = "-9999px";
  document.body.appendChild(textarea);
  textarea.select();
  const copied = document.execCommand("copy");
  document.body.removeChild(textarea);
  showToast(copied ? "Plan copied." : "Copy failed.");
}

function buildExportText() {
  const usage = getUsageCounts();
  if (!state.plan.length && !usage.size) return "";

  const lines = ["MealCube Plan", ""];
  if (state.plan.length) {
    state.plan.forEach((day, index) => {
      lines.push(`Day ${index + 1} - ${formatDate(parseISODate(day.date))}`);
      Object.entries(day.slots || {}).forEach(([slot, recipeId]) => {
        const recipe = catalogById.get(recipeId);
        lines.push(`  ${slot}: ${recipe ? recipe.name : "None"}`);
      });
    });
  } else {
    lines.push("Selected Recipes");
    selectedRecipes().forEach((recipe) => lines.push(`  ${recipe.name}`));
  }

  lines.push("", "Shopping Cart");
  buildShoppingItems().forEach((item) => {
    lines.push(`- ${item.group}: ${item.item}`);
  });

  return lines.join("\n");
}

function downloadPlan() {
  const payload = {
    generatedAt: new Date().toISOString(),
    settings: {
      startDate: state.startDate,
      weeks: state.weeks,
      slots: state.slots
    },
    selectedRecipes: selectedRecipes(),
    plan: state.plan,
    shoppingCart: buildShoppingItems()
  };
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `mealcube-plan-${state.startDate || todayISO()}.json`;
  link.click();
  URL.revokeObjectURL(url);
}

let toastTimer = null;
function showToast(message) {
  const toast = $("#toast");
  toast.textContent = message;
  toast.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove("show"), 1800);
}

function renderAll() {
  renderThemeChips();
  renderCatalog();
  renderPlan();
}

setupControls();
renderAll();
