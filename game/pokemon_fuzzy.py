import numpy as np
import skfuzzy as fuzz
from skfuzzy import control as ctrl

'''
Cria um sistema Fuzzy que recebe como input a diferença dos niveis
e o efeito do ataque e devolve como input a probabilidade de ganhar
'''

def calculate_prob(level_input, effect_input):
    level = ctrl.Antecedent(np.arange(-7, 7, 1), 'level')
    effect = ctrl.Antecedent(np.arange(0, 4.5, 0.5), 'effect')

    prob = ctrl.Consequent(np.arange(0, 1.1, 0.1), 'prob')

    level['low'] = np.array([
    1.0, 1.0, 0.9, 0.8, 0.6, 0.4, 0.2,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    level['equal'] = np.array([
        0.0, 0.0, 0.0, 0.0, 0.1, 0.3, 0.6,
        1.0, 0.4, 0.1, 0.0, 0.0, 0.0, 0.0])
    level['high'] = np.array([
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.1, 0.5, 0.8, 1.0, 1.0, 1.0, 1.0])

    effect['weak'] = np.array([1.0, 0.6, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    effect['normal'] = np.array([0.0, 0.0, 0.3, 0.7, 1.0, 0.7, 0.3, 0.0, 0.0])
    effect['strong'] = np.array([0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.8, 0.9, 1.0])

    prob['low'] = np.array([1.0, 0.9, 0.7, 0.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    prob['medium'] = np.array([0.0, 0.0, 0.0, 0.2, 0.5, 0.8, 0.5, 0.2, 0.0, 0.0, 0.0])
    prob['high'] = np.array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.4, 0.7, 0.9, 1.0])

    rule1 = ctrl.Rule(level['low'] & effect['weak'], prob['low'])
    rule2 = ctrl.Rule(level['low'] & effect['normal'], prob['low'])
    rule3 = ctrl.Rule(level['low'] & effect['strong'], prob['medium'])

    rule4 = ctrl.Rule(level['equal'] & effect['weak'], prob['low'])
    rule5 = ctrl.Rule(level['equal'] & effect['normal'], prob['medium'])
    rule6 = ctrl.Rule(level['equal'] & effect['strong'], prob['high'])

    rule7 = ctrl.Rule(level['high'] & effect['weak'], prob['medium'])
    rule8 = ctrl.Rule(level['high'] & effect['normal'], prob['high'])
    rule9 = ctrl.Rule(level['high'] & effect['strong'], prob['high'])

    l_pos = np.where(level.universe == level_input)[0][0]
    e_pos = np.where(effect.universe == effect_input)[0][0]

    l_low   = level['low'].mf[l_pos]
    l_equal = level['equal'].mf[l_pos]
    l_high  = level['high'].mf[l_pos]

    e_weak   = effect['weak'].mf[e_pos]
    e_normal = effect['normal'].mf[e_pos]
    e_strong = effect['strong'].mf[e_pos]
    
    r1 = min(l_low, e_weak)
    r2 = min(l_low, e_normal)
    r3 = min(l_low, e_strong)

    r4 = min(l_equal, e_weak)
    r5 = min(l_equal, e_normal)
    r6 = min(l_equal, e_strong)

    r7 = min(l_high, e_weak)
    r8 = min(l_high, e_normal)
    r9 = min(l_high, e_strong)

    rule1_activation = np.minimum(r1, prob['low'].mf)
    rule2_activation = np.minimum(r2, prob['low'].mf)
    rule3_activation = np.minimum(r3, prob['medium'].mf)

    rule4_activation = np.minimum(r4, prob['low'].mf)
    rule5_activation = np.minimum(r5, prob['medium'].mf)
    rule6_activation = np.minimum(r6, prob['high'].mf)

    rule7_activation = np.minimum(r7, prob['medium'].mf)
    rule8_activation = np.minimum(r8, prob['high'].mf)
    rule9_activation = np.minimum(r9, prob['high'].mf)

    aggregated = np.maximum.reduce([rule1_activation, rule2_activation, rule3_activation, rule4_activation,
                                    rule5_activation, rule6_activation, rule7_activation, rule8_activation,
                                    rule9_activation])
    
    prob_output = fuzz.defuzz(prob.universe, aggregated, "centroid")

    #print(f"Universes: \n level: {level.universe} \n effect {effect.universe} \n prob: {prob.universe}")
    return prob_output

# print("(-2,1.0):", calculate_prob(-2, 1.0))
# print("(-1,1.0):", calculate_prob(-1, 1.0))
# print("(0,1.0):", calculate_prob(0, 1.0))
# print("(1,1.0):", calculate_prob(1, 1.0))
# print("(2,1.0):", calculate_prob(2, 1.0))
# print("(3,1.0):", calculate_prob(3, 1.0))
# print("(2,2.0):", calculate_prob(2, 2.0))
# print("(2,0.5):", calculate_prob(2, 0.5))