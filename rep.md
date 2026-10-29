# تقرير شامل: اعتماديات المشروع وفجوات فئات التحسين

> **النطاق:** `rust/src/` و `lib/src/modules/` وملفات البناء (`Cargo.toml`, `build.rs`, `pubspec.yaml`).
> **تاريخ التقرير:** 2026-10-29
> **الهدف:** الإجابة على سؤالين — (1) هل المشروع pure Rust أم يحتوي أغلفة C/C++؟ (2) ما فئات مسائل التحسين المفقودة القابلة للتنفيذ؟

---

## المحتويات

1. [الخلاصة التنفيذية](#1-الخلاصة-التنفيذية)
2. [تدقيق الاعتماديات](#2-تدقيق-الاعتماديات)
3. [القدرات المدعومة اليوم](#3-القدرات-المدعومة-اليوم)
4. [فجوات فئات المسائل](#4-فجوات-فئات-المسائل)
5. [فجوات طبقة النمذجة في Dart](#5-فجوات-طبقة-النمذجة-في-dart)
6. [فجوات العقود DTO والـ Routing](#6-فجوات-العقود-dto-والـ-routing)
7. [فجوات تشغيلية وتشخيصية](#7-فجوات-تشغيلية-وتشخيصية)
8. [خطة تنفيذ مرتبة بالعائد/الجهد](#8-خطة-تنفيذ-مرتبة-بالعائدالجهد)
9. [مزالق تقنية يجب الحذر منها](#9-مزالق-تقنية-يجب-الحذر-منها)
10. [التوصية النهائية](#10-التوصية-النهائية)

---

## 1. الخلاصة التنفيذية

1. **المشروع ليس pure Rust بالكامل**، لكن التلوث محدود جدًا: هناك **اعتمادية C++ واحدة فقط** هي `highs` (عبر `highs-sys`)، وهي **اختيارية ومفعّلة افتراضيًا**.
2. عند البناء بـ `--no-default-features` تتحول حزمة الحلول بالكامل إلى **Rust خالص** (`clarabel` + `microlp` عبر `good_lp`)، وهذا هو مسار الويب/WASM.
3. أكبر فجوة **ليست في المحركات بل في العقود**: `clarabel` يدعم QP/SOCP أصلًا، لكن الـ DTOs والـ AST والـ compiler خطية 100%، و`has_quadratic` مثبّت على `false` في مكانين. أي أن **QP هي أرخص مكسب متاح**.
4. الفجوات الحقيقية الكبيرة: **MILP بدون C++**، **NLP/MINLP**، **القيود المنطقية المتقدمة (SOS/indicator)**، **التشخيص (IIS/duals/gap)**، و**التحليل الحساسي**.

---

## 2. تدقيق الاعتماديات

### 2.1 اعتماديات Rust المباشرة

من `rust/Cargo.toml`:

| الحزمة | الإصدار | النوع | يحتاج مترجم/C++؟ | ملاحظات |
|---|---|---|---|---|
| `anyhow` | 1.0.104 | Rust خالص | لا | تسلسل الأخطاء الداخلية |
| `async-trait` | 0.1.89 | Rust خالص (macro) | لا | لتعريف `SolverEngine` |
| `clarabel` | 0.11.1 | **Rust خالص** | لا | internal-point conic solver |
| `flutter_rust_bridge` | `=2.13.0` | Rust + `dart-sys` | **C وقت البناء فقط** | `dart-sys` يستخدم `cc` لتوليد shim؛ لا C++ ولا مكتبة solvers أصلية |
| `good_lp` | 1.15.3 | Rust خالص | لا | `default-features = false` + `microlp` فقط |
| `highs` | 2.4.0 | **غلاف C++** | **نعم** | `optional = true` لكنه داخل `default` |
| `thiserror` | 2.0.21 | Rust خالص (macro) | لا | تعريف `FrbSolverError` |

### 2.2 سلسلة HiGHS — الاعتمادية الأصلية الوحيدة

```
highs 2.4.0
└── highs-sys 1.15.0
    ├── bindgen   (توليد bindings من headers الـ C++)
    └── cmake     (بناء مصدر HiGHS الـ C++ داخل الكريت)
        → cargo:rustc-link-lib=stdc++   (Linux/Android)
```

**النتائج العملية:**

- بناء الحزمة الافتراضي يتطلب: **Rust toolchain + C++ compiler + CMake + رأسيات C++ قياسية**.
- على Android، `highs-sys` يربط `stdc++` وهذا سبب وجود المعالجة الخاصة في `rust/build.rs` (ربط `libc++_static` بدلًا منه).
- لا يمكن استخدام HiGHS في **WASM** أصلًا؛ لهذا وُجد مسار `--no-default-features`.
- هذه هي النقطة الوحيدة التي تكسر قاعدة "Rust خالص"، وهي **معزولة خلف feature flag** وليست منتشرة في الكود (كل الاستخدام محكوم بـ `#[cfg(feature = "highs")]` في `registry.rs`).

### 2.3 جانب Dart

`pubspec.yaml` لا يحتوي أي حزمة solvers أصلية. الاعتماديات هي:

```
flutter_rust_bridge, collection, equatable, freezed_annotation, logging, meta
```

أي أن **كل المنطق العددي يمر عبر جسر FRB إلى Rust**، ولا توجد طبقة C/C++ على جانب Dart. هذه نقطة قوة معمارية.

### 2.4 الحكم النهائي

| السؤال | الجواب |
|---|---|
| هل المشروع pure Rust؟ | **لا، لكن بنسبة ~95%** |
| كم اعتمادية C/C++؟ | **واحدة**: HiGHS (C++) |
| هل يمكن بناء نسخة pure Rust؟ | **نعم**: `--no-default-features` → Clarabel + MicroLP |
| هل توجد أغلفة C++ أخرى مخفية؟ | **لا**. `dart-sys`/`cc` بناء-time فقط، ولا يُضمّن runtime C++ |
| هل التلوث معزول؟ | **نعم**، عبر feature واحد + `cfg` + `build.rs` مركزي |

### 2.5 مصفوفة القيود المترتبة

| البُعد | مع `highs` | بدون `highs` |
|---|---|---|
| WASM / Web | ❌ مستحيل | ✅ ممكن |
| Android / iOS cross-compile | ⚠️ يحتاج C++ toolchain + معالجة `build.rs` | ✅ أبسط بكثير |
| وقت البناء | أطول (cmake يبني HiGHS) | أسرع بكثير |
| حجم الحزمة | أكبر | أصغر |
| مساحة CVE / supply chain | أكبر (كود C++ + bindgen) | أصغر |
| MILP | ✅ | ❌ لا يوجد بديل |
| LP الأداء | ✅ ممتاز | ⚠️ MicroLP أبسط وأبطأ |

**التراخيص** (بحسب ما تعلنه الحزم): HiGHS = MIT، Clarabel = Apache-2.0، good_lp/microlp = MIT. لا تعارض مع الاستخدام التجاري، لكن Apache-2.0 يتطلب حفظ NOTICE.

---

## 3. القدرات المدعومة اليوم

### 3.1 فئات المسائل

| الفئة | مدعومة؟ | المحرك | ملاحظة |
|---|---|---|---|
| LP مستمر | ✅ | HiGHS / Clarabel / MicroLP | ثلاثة محركات |
| MILP (integer/binary) | ✅ | **HiGHS فقط** | البقية ترفض عبر `validate` |
| Bounds على المتغيرات | ✅ | الثلاثة | `None` = بلا حد |
| `<=`, `>=`, `=` | ✅ | الثلاثة | `>=` يُطبّع بالانعكاس في MicroLP |
| Min / Max + ثابت في الهدف | ✅ | الثلاثة | الثابت يُضاف بعد الحل |
| Time limit | ✅ | الثلاثة | يظهر كـ `TimeLimitExceeded` |
| Threads / logging | ✅ | حسب المحرك | |
| Dual values | ⚠️ جزئي | **HiGHS للمستمر فقط** | `None` لـ Clarabel و MicroLP ولـ MILP |
| QP / SOCP / Conic | ❌ | — | الأعلام موجودة لكن غير مستخدمة |

### 3.2 الحالات المُعادة

```
Optimal, Infeasible, Unbounded, TimeLimitExceeded, NumericalError, Unknown
```

لا يوجد: `Feasible` (حل مقبول غير مُثبت)، ولا `IterationLimit`، ولا `GapLimit` كحالة مستقلة (MicroLP يحوّله إلى `TimeLimitExceeded`).

### 3.3 ملاحظات على تنفيذ المحركات

| المحرك | ملف | الحالة الفعلية |
|---|---|---|
| HiGHS | `rust/src/engine/highs/adapter.rs` | LP + MILP، duals للمستمر فقط |
| Clarabel | `rust/src/engine/clarabel/adapter.rs` | يُستخدم كـ LP فقط: `P = CscMatrix::zeros((n, n))`، و`dual_values: None` |
| MicroLP | `rust/src/engine/microlp/adapter.rs` | LP فقط عبر `good_lp`، لا duals، `iterations = 0` |

---

## 4. فجوات فئات المسائل

| # | الفئة | الحالة | ما ينقص بالضبط | الجهد |
|---|---|---|---|---|
| 1 | **QP** (هدف تربيعي محدب) | ❌ | `P` matrix في DTO + بناء `P` في Clarabel + AST | **S** |
| 2 | **QCQP** (قيود تربيعية محدبة) | ❌ | تحويل إلى SOCP + DTO cones | M |
| 3 | **SOCP** | ❌ | DTO للـ cones + AST `norm2` | M |
| 4 | **Conic عام** (EXP / POW / PSD) | ❌ | Clarabel يدعمها، لا يوجد تمثيل في DTO | M |
| 5 | **MIQP / MISOCP** | ❌ | لا محرك، ولا حتى HiGHS مغلّف لهذا الشكل | L |
| 6 | **MILP بدون C++** | ❌ | لا crate Rust ناضج؛ يحتاج B&B مكتوب يدويًا | **XL** |
| 7 | **NLP** (غير خطي عام) | ❌ | لا gradient/Hessian، لا solver مناسب | XL |
| 8 | **MINLP** | ❌ | يعتمد على NLP + MILP | XL+ |
| 9 | **Global optimization** (غير محدب) | ❌ | لا branch-and-bound مكاني، لا interval arithmetic | XL+ |
| 10 | **CP / CP-SAT / SAT** | ❌ | نموذج مختلف كليًا (domain propagation) | XL |
| 11 | **SOS1 / SOS2** | ❌ | لا نوع متغير ولا قيد في DTO | M |
| 12 | **Indicator constraints** | ❌ | لا تمثيل `b=1 ⇒ expr ≤ rhs` | M |
| 13 | **Semi-continuous / semi-integer** | ❌ | `FrbVariableType` فيه 3 أنواع فقط | S–M |
| 14 | **Multi-objective / lexicographic** | ❌ | لا طبقة أهداف متعددة | M |
| 15 | **Goal programming** | ❌ | يحتاج انحرافات + أوزان | M |
| 16 | **Robust / stochastic** | ❌ | لا سيناريوهات ولا عدم يقين | XL |
| 17 | **Decomposition** (Benders / Dantzig-Wolfe / column generation) | ❌ | لا إطار decomposition | XL |
| 18 | **Network flow / assignment / transportation** | ⚠️ | تُنمذج كـ LP/MILP فقط، لا خوارزميات متخصصة | L |
| 19 | **TSP / VRP / scheduling المتخصصة** | ⚠️ | ممكن كـ MILP لكن بدون cuts/heuristics مخصصة | XL |
| 20 | **Piecewise linear** | ❌ | لا SOS2 ولا صياغة lambda | M |

**مفتاح الجهد:** S = أيام، M = 1–2 أسبوع، L = 3–6 أسابيع، XL = شهور.

---

## 5. فجوات طبقة النمذجة في Dart

الـ AST الحالي في `lib/src/modules/modeling/ast/` يدعم **خمس عقد فقط**:

```
AddNode, MultiplyNode (× ثابت فقط), NegateNode, ConstantNode, VariableNode
```

المعاملات المتاحة:

| القدرة | الحالة |
|---|---|
| `x + y`, `3*x`, `-x` | ✅ |
| `x * y` (متغير × متغير) | ❌ يرمي `ModelValidationException` |
| `x^2` | ❌ |
| قسمة على متغير | ❌ |
| `abs`, `min`, `max` | ❌ |
| `sqrt`, `exp`, `log`, `pow` | ❌ |
| دوال مثلثية | ❌ |
| `norm2` / قيود مخروطية | ❌ |
| هدف تربيعي | ❌ |
| قيود تربيعية | ❌ |
| Piecewise linear | ❌ |

وفي `logic.dart` يوجد **ثلاثة helpers فقط**: `exactlyOne`, `atMostOne`, `atLeastOne`. لا يوجد:

- `implies(a, b)` أو reified constraints
- Big-M helper
- `allDifferent`
- `element` constraint
- `ifThenElse`

**السبب الجذري:** `compiler.dart` يعلن صراحةً أنه خطي فقط، ويتعامل مع `visitVariableNode` كـ `_NonConstant` عند حساب معامل ثابت. لذلك أي منتج لمتغيرين غير قابل للتمثيل.

---

## 6. فجوات العقود DTO والـ Routing

هذه أهم فجوة لأنها **تحجب قدرات موجودة بالفعل**:

| الموضع | المشكلة |
|---|---|
| `rust/src/engine/registry.rs:129` | `let has_quadratic = false;` مثبّت |
| `lib/src/modules/modeling/model.dart` | `hasQuadratic: false` مثبّت |
| `FrbObjectiveDto` | خطي فقط: `terms: Vec<FrbTermDto>` — لا `Q` |
| `FrbConstraintDto` | خطي فقط — لا quadratic ولا cone |
| `clarabel/adapter.rs` | `P = CscMatrix::zeros((n, n))` — أي LP فقط |
| `clarabel/adapter.rs` | `dual_values: None` رغم أن Clarabel يعيد duals |
| `microlp/adapter.rs` | `dual_values: None` (good_lp لا يعرضها) |
| `dto_response.rs` | لا `mip_gap`، لا `bound`، لا `solution_pool` |
| `FrbSolveOptionsDto` | لا `mip_gap`، لا `warm_start`، لا `presolve`، لا `node_limit` |
| `FrbSolveStatistics` | `iterations` غالبًا 0 (good_lp لا يعرضها) |
| `FrbVariableType` | 3 أنواع فقط: `Continuous`, `Integer`, `Binary` |

**ملاحظة مهمة:** تعليق `registry.rs` يقول إن `clarabel` يُختار "once quadratic DTOs mark a QP/SOCP shape" — أي أن التصميم **معدّ مسبقًا** لهذه الإضافة. هذا يقلل تكلفة QP بشكل كبير.

---

## 7. فجوات تشغيلية وتشخيصية

| القدرة | الحالة | الأثر |
|---|---|---|
| IIS (تشخيص عدم الإمكانية) | ❌ | المستخدم يحصل على `Infeasible` بلا سبب |
| Elastic / soft constraints | ❌ | لا يمكن معرفة أي قيد يسبب التعارض |
| Dual values موحّدة | ⚠️ | التحليل الحساسي غير ممكن إلا مع HiGHS LP |
| Ranging / sensitivity analysis | ❌ | لا تحليل تغيّر coefficients/RHS |
| Warm start / basis reuse | ❌ | كل حل من الصفر |
| MIP gap control | ❌ | لا يمكن الموازنة بين الوقت والجودة |
| Solution pool | ❌ | لا حلول بديلة |
| Lazy constraints / callbacks | ❌ | يمنع cutting-plane من المستخدم |
| Progress callbacks | ❌ | لا تقدم أثناء الحل الطويل |
| Presolve control | ❌ | لا تحكم في الـ presolve |

---

## 8. خطة تنفيذ مرتبة بالعائد/الجهد

### المرحلة 1 — QP (أعلى عائد، أقل جهد)

**لماذا أولًا:** Clarabel يدعم QP بالفعل، والـ routing مُهيّأ، والـ adapter يحتاج فقط بناء `P`.

**التغييرات المطلوبة:**

1. **DTO** (`dto_request.rs`): إضافة حقل جديد **اختياري** للحفاظ على توافق FFI:

   ```rust
   pub struct FrbObjectiveDto {
       pub sense: FrbOptimizationSense,
       pub terms: Vec<FrbTermDto>,
       pub constant: f64,
       // جديد: (i, j, coef) مع i <= j، والقيمة تمثل معامل 0.5*x'Qx
       pub quadratic_terms: Option<Vec<FrbQuadTermDto>>,
   }
   ```

   الأفضل توثيق **اتفاقية العامل 0.5** صراحةً لأن Clarabel و HiGHS كلاهما يستخدم `0.5 x'Px + q'x`.

2. **Clarabel adapter**: بناء `P` من `quadratic_terms` بدل `zeros`، مع فحص تناظر + PSD (أو ترك Clarabel يفشل برسالة واضحة).

3. **Routing**: `has_quadratic = request.objective.quadratic_terms.as_ref().is_some_and(|q| !q.is_empty())`.

4. **Dart AST**: إضافة `QuadNode` أو السماح بـ `MultiplyNode` عندما يكون الطرفان غير ثابتين، ثم توليد `quadratic_terms` في `compiler.dart`.

5. **Dart `model.dart`**: إزالة `hasQuadratic: false` الثابت.

**الجهد:** صغير–متوسط.
**الأثر:** يفتح فئة كاملة من المسائل (portfolio، least-squares، SVM، MPC).

### المرحلة 2 — SOCP / Conic

- إضافة DTO للـ cones: `Nonnegative`, `SecondOrder`, `Exponential`, `Power`, `PSD`.
- Clarabel يدعمها أصلًا في `SupportedConeT`.
- إضافة `norm2` إلى AST.
- تفعيل `supports_socp` فعليًا بدل كونه علمًا وصفيًا.

**الجهد:** متوسط.
**الأثر:** robust optimization، geometric programming، QCQP محدب.

### المرحلة 3 — Duals تشخيصية

- تعريض duals من Clarabel (`z` للمخروط) مع توحيد **إشارة** الـ duals بين المحركات.
- duals لـ MicroLP غير متاحة عبر good_lp — إما استخدام `microlp` مباشرة أو توثيق عدم الدعم.

**الجهد:** صغير–متوسط.
**الأثر:** يفتح التحليل الحساسي والأسعار الظلية.

### المرحلة 4 — MILP بدون C++ (إن كان WASM هدفًا)

هذه أصعب فجوة. الخيارات:

| الخيار | الوصف | الحكم |
|---|---|---|
| كتابة B&B فوق LP | relaxation عبر MicroLP/Clarabel + branching + cuts | جهد ضخم، أداء محدود |
| `russcip` | غلاف C++ لـ SCIP | يكسر pure Rust |
| `highs` | الحالي | C++ |
| `lp-solvers` | تشغيل solver خارجي كـ process | لا يصلح لـ mobile/WASM |
| الإبقاء على HiGHS | MILP أصلي فقط، بدون ويب | **الأكثر واقعية** |

**التوصية:** لا تحاول MILP pure Rust الآن. وثّق بوضوح أن MILP غير متاح على الويب، وأبقِ HiGHS للمنصات الأصلية.

### المرحلة 5 — قيود منطقية متقدمة

- `SOS1` / `SOS2` (HiGHS يدعمها أصلًا).
- Indicator constraints (HiGHS يدعمها).
- Semi-continuous variables (HiGHS يدعمها).
- Helpers في Dart: `implies`, `bigM`, `allDifferent`, `element`.

هذه **رخيصة نسبيًا** لأن HiGHS يملك الدعم، والمطلوب فقط توسيع DTO + AST + Helpers.

### المرحلة 6 — ما يوصى بتأجيله

NLP، MINLP، global optimization، CP/SAT، stochastic/robust، decomposition. هذه ليست "إضافات" بل **محركات جديدة بمنطق مختلف تمامًا**، وتكلفتها أعلى من قيمة إضافتها لمكتبة تحسين خطية/مخروطية.

---

## 9. مزالق تقنية يجب الحذر منها

1. **اتفاقية العامل 0.5 في QP**
   Clarabel يحل `min 0.5 x'Px + q'x`. إذا عرّفت `Q` كـ `x'Qx` بدون 0.5، ستحصل على نتائج مضاعفة أو منصفة. **يجب توثيق الاتفاقية في DTO نفسه** لأنها ستنتقل إلى Dart عبر تعليقات FRB.

2. **إشارة الـ duals**
   HiGHS و Clarabel قد يختلفان في إشارة duals للقيود `<=` مقابل `>=`. بدون توحيد، التحليل الحساسي سيعطي إشارات معكوسة.

3. **Clarabel يحتاج `P` متماثلًا و PSD**
   لا يوجد فحص حاليًا. إما تفحص PSD (تحليل eigen مكلف) أو تلتقط خطأ Clarabel وتعيد `NumericalError` برسالة مفهومة.

4. **`panic = "abort"` في release**
   مع FFI، أي panic داخل solver سيُسقط العملية بالكامل بدل أن يُرفع كخطأ. هذا خطر حقيقي على تطبيقات mobile. يستحق مراجعة منفصلة.

5. **توافق FFI عند إضافة حقول**
   تعليق `dto_request.rs` يشترط: *"new fields must be Optional or have wire-compatible defaults"*. إذن **لا تضف `Vec<...>` غير اختياري** — استخدم `Option<Vec<...>>` أو نوعًا جديدًا اختياريًا.

6. **`supports_qp` / `supports_socp` حاليًا "أعلام كاذبة"**
   التعليق نفسه يقول *"Reserved"*. لكن اختبار `capability_table_is_honest` يؤكد `clarabel.supports_qp == true`. هذا **تناقض دلالي**: العلم يقول نعم والـ DTO لا يستطيع نقل QP. يستحق التحقق من أن الاختبار يعكس النية الحقيقية.

7. **`iterations` غير موثوق**
   `FrbSolveStatistics::iterations` يساوي 0 دائمًا مع MicroLP ومعظم مسارات Clarabel. لا تبنِ عليه أي منطق.

---

## 10. التوصية النهائية

**الاعتماديات:** لا مشكلة جوهرية. C++ محصور في HiGHS خلف feature، ويمكن التحكم به بالكامل. المشروع نظيف معماريًا بهذا المعيار.

**الفجوات:** رتّبها هكذا:

```
QP            ← ابدأ هنا (أرخص، أعلى عائد، البنية جاهزة)
SOCP/Conic    ← امتداد طبيعي لـ QP على Clarabel
Duals         ← تشخيص وتحليل حساسي
SOS/Indicator ← رخيص لأن HiGHS يدعمه
MILP on Web   ← أجّل أو تخلى عنه
NLP/MINLP/CP  ← خارج النطاق الحالي
```

**النقطة الأهم:** المشكلة ليست أن المحركات ضعيفة — `clarabel` محرك conic قوي جدًا — بل أن **العقود والـ AST لا تعبر عن قدراته**. أكبر عائد لكل ساعة عمل موجود في توسيع `FrbObjectiveDto` و`compiler.dart`، وليس في إضافة محرك جديد.

---

## ملحق: خريطة الملفات المرجعية

| الملف | الدور |
|---|---|
| `rust/Cargo.toml` | تعريف الاعتماديات والـ features؛ `default = ["highs"]` |
| `rust/Cargo.lock` | الرسم الكامل للاعتماديات المحسومة |
| `rust/build.rs` | معالجة ربط `libc++_static` على Android |
| `rust/src/engine/traits.rs` | `EngineCapabilities` + `validate` |
| `rust/src/engine/registry.rs` | جدول التوجيه و`route(.., has_quadratic)` |
| `rust/src/engine/highs/adapter.rs` | LP/MILP عبر C++ |
| `rust/src/engine/clarabel/adapter.rs` | conic مقيّد حاليًا إلى LP |
| `rust/src/engine/microlp/adapter.rs` | LP خالص عبر good_lp |
| `rust/src/models/dto_request.rs` | عقود الطلب (خطية بالكامل) |
| `rust/src/models/dto_response.rs` | عقود الاستجابة والحالات |
| `lib/src/modules/modeling/compiler.dart` | ترجمة AST الخطي فقط |
| `lib/src/modules/modeling/ast/*.dart` | خمس عقد رياضية فقط |
| `lib/src/modules/modeling/model.dart` | `hasQuadratic: false` مثبّت |
| `lib/src/modules/solving/registry.dart` | سجل قدرات مرآة للجانب Rust |
| `pubspec.yaml` | لا اعتماديات solvers أصلية |
